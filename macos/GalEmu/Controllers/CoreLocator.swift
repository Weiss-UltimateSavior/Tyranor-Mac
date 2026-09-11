import Foundation

enum CoreLocator {
    static let defaultKrkrsdl3Path = "/Users/weiss/opencode/krkrsdl3_build/out/macos/Release/krkrsdl3"

    static func krkrsdl3Executable() -> URL? {
        let configured = UserDefaults.standard.string(forKey: "core.krkrsdl3.path") ?? ""
        let candidates = [configured, defaultKrkrsdl3Path].filter { !$0.isEmpty }
        if let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: path)
        }
        return Bundle.main.url(forResource: "krkrsdl3", withExtension: nil)
    }
}
