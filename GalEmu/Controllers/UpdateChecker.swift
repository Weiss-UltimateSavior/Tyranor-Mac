import Combine
import Foundation

struct UpdateRelease: Equatable {
    let version: String
    let tag: String
    let name: String
    let notes: String
    let pageURL: URL?
    let isPrerelease: Bool
    let publishedAt: Date?
}

@MainActor
final class UpdateChecker: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(UpdateRelease)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isManualCheck = false

    private let skippedVersionKey = "update.skippedVersion"

    var currentVersion: String {
        AppInfo.version
    }

    func check(manual: Bool) async {
        guard state != .checking else { return }
        isManualCheck = manual
        state = .checking

        do {
            let release = try await fetchLatestRelease()
            guard let release else {
                state = .upToDate
                return
            }
            guard Self.isNewer(release.version, than: currentVersion) else {
                state = .upToDate
                return
            }
            if !manual, release.version == skippedVersion {
                state = .idle
                return
            }
            state = .available(release)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func skip(_ release: UpdateRelease) {
        UserDefaults.standard.set(release.version, forKey: skippedVersionKey)
        state = .idle
    }

    func reset() {
        state = .idle
    }

    private var skippedVersion: String? {
        UserDefaults.standard.string(forKey: skippedVersionKey)
    }

    private func fetchLatestRelease() async throws -> UpdateRelease? {
        guard let url = URL(string: "https://api.github.com/repos/\(AppInfo.repository)/releases") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("TyranorMac/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw UpdateError.network
        }
        guard (200..<300).contains(http.statusCode) else {
            throw UpdateError.http(http.statusCode)
        }
        guard let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        for item in list {
            if (item["draft"] as? Bool) == true { continue }
            guard let tag = item["tag_name"] as? String, !tag.isEmpty else { continue }
            let version = Self.normalizedVersion(tag)
            guard !version.isEmpty else { continue }

            let publishedAt = (item["published_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
            return UpdateRelease(
                version: version,
                tag: tag,
                name: (item["name"] as? String) ?? tag,
                notes: (item["body"] as? String) ?? "",
                pageURL: (item["html_url"] as? String).flatMap(URL.init(string:)),
                isPrerelease: (item["prerelease"] as? Bool) ?? false,
                publishedAt: publishedAt
            )
        }
        return nil
    }

    static func normalizedVersion(_ tag: String) -> String {
        var value = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") {
            value.removeFirst()
        }
        return value
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let remoteParts = components(remote)
        let localParts = components(local)
        let count = max(remoteParts.count, localParts.count)
        for index in 0..<count {
            let remoteValue = index < remoteParts.count ? remoteParts[index] : 0
            let localValue = index < localParts.count ? localParts[index] : 0
            if remoteValue != localValue {
                return remoteValue > localValue
            }
        }
        return false
    }

    private static func components(_ version: String) -> [Int] {
        version.split(separator: ".").map { part in
            Int(part.prefix(while: \.isNumber)) ?? 0
        }
    }

    enum UpdateError: LocalizedError {
        case network
        case http(Int)

        var errorDescription: String? {
            switch self {
            case .network:
                return "检查更新失败：网络错误"
            case let .http(code):
                return "检查更新失败：HTTP \(code)"
            }
        }
    }
}
