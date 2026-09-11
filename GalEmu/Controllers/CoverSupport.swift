import CryptoKit
import Foundation

enum CoverSupport {
    static let localCoverNames = [
        "cover.jpg", "cover.png", "cover.webp", "cover.jpeg", "cover.bmp", "icon.png",
    ]

    static func localCoverPath(in directory: URL) -> String? {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for name in localCoverNames {
            if let match = files.first(where: { $0.lastPathComponent.lowercased() == name }) {
                return match.path
            }
        }
        return nil
    }

    static func cleanTitle(_ raw: String) -> String {
        let editionWords = ["汉化", "中文版", "日文版", "体验版"]
        var text = raw
        text = text.replacingOccurrences(
            of: #"\[[^\]]*\]|【[^】]*】"#,
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"[\[\]【】]"#,
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"[（(].*"#,
            with: " ",
            options: .regularExpression
        )
        let escaped = editionWords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
        text = text.replacingOccurrences(
            of: "(?i)\\b(complete|trial|patch)\\b|\(escaped)",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(of: "_", with: " ")
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : text
    }

    static func stableKey(_ value: String) -> String {
        let digest = Insecure.SHA1.hash(data: Data(value.utf8))
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}
