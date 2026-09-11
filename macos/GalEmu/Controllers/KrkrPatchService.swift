import Foundation

struct KirikiroidPatchEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let brand: String
    let path: String
    let name: String
    let patches: [String]
}

enum KrkrPatchError: LocalizedError {
    case indexFailed
    case downloadFailed(String)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .indexFailed:
            return "补丁索引获取失败，请检查网络"
        case let .downloadFailed(fileName):
            return "补丁下载失败：\(fileName)"
        case .writeFailed:
            return "补丁写入游戏目录失败"
        }
    }
}

enum KrkrPatchService {
    static let indexURL = "https://zeas2.github.io/Kirikiroid2_patch/patch/alldata.js"
    static let baseURL = "https://zeas2.github.io/Kirikiroid2_patch/patch/"
    private static let maxPatchBytes = 200 * 1024 * 1024

    static func fetchIndex() async throws -> [KirikiroidPatchEntry] {
        guard let url = URL(string: indexURL) else { throw KrkrPatchError.indexFailed }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let text = String(data: data, encoding: .utf8) else {
            throw KrkrPatchError.indexFailed
        }

        let regex = try NSRegularExpression(
            pattern: #"\[(\d+),\s*"(.+?)",\s*"(.+?)",\s*"(.+?)",\s*\[(.+?)\]\],?"#
        )
        var entries: [KirikiroidPatchEntry] = []

        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let match = regex.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
            ) else { continue }

            func group(_ index: Int) -> String {
                guard let range = Range(match.range(at: index), in: trimmed) else { return "" }
                return String(trimmed[range])
            }

            let patches = group(5)
                .components(separatedBy: ",")
                .map {
                    $0.trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
                .filter { !$0.isEmpty }
                .map { baseURL + $0 }

            entries.append(
                KirikiroidPatchEntry(
                    timestamp: Date(timeIntervalSince1970: TimeInterval(Int64(group(1)) ?? 0)),
                    brand: group(2),
                    path: group(3),
                    name: group(4),
                    patches: patches
                )
            )
        }

        return entries.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func install(
        entry: KirikiroidPatchEntry,
        into game: Game,
        progress: @escaping (String) -> Void
    ) async throws -> [String] {
        guard !entry.patches.isEmpty else { throw KrkrPatchError.downloadFailed("该补丁没有文件") }
        let directory = URL(fileURLWithPath: game.metadata.directoryPath)
        var installed: [String] = []

        for urlString in entry.patches {
            guard let url = URL(string: urlString) else { continue }
            let fileName = fileName(from: urlString)
            progress("下载 \(fileName)")

            var request = URLRequest(url: url)
            request.timeoutInterval = 120
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  data.count <= maxPatchBytes else {
                throw KrkrPatchError.downloadFailed(fileName)
            }

            progress("写入 \(fileName)")
            do {
                try data.write(to: directory.appendingPathComponent(fileName), options: .atomic)
            } catch {
                throw KrkrPatchError.writeFailed
            }
            installed.append(fileName)
        }
        return installed
    }

    static func fileName(from urlString: String) -> String {
        let raw = URL(string: urlString)?.lastPathComponent ?? "patch.xp3"
        let decoded = raw.removingPercentEncoding ?? raw
        let invalid = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return decoded.components(separatedBy: invalid).joined(separator: "_")
    }
}
