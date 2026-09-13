import Foundation

enum CoreLocator {
    static let defaultKrkrsdl3Path = "/Users/weiss/opencode/krkrsdl3_build/out/macos/Release/krkrsdl3"
    static let defaultOnsyuriPath = "/Users/weiss/github- engine/OnscripterYuri/build_darwin/onsyuri"
    static let defaultArtemisPath = "/Users/weiss/opencode/artemis-compat/build-mac/artemis-mac"

    static func krkrsdl3Executable() -> URL? {
        executable(
            configuredKey: "core.krkrsdl3.path",
            candidates: [
                projectPath("engine/kr/krkrsdl3"),
                bundlePath("engine/kr/krkrsdl3"),
                defaultKrkrsdl3Path,
            ],
            named: "krkrsdl3"
        )
    }

    static func onsyuriExecutable() -> URL? {
        executable(
            configuredKey: "core.onsyuri.path",
            candidates: [
                projectPath("engine/ons/onsyuri"),
                bundlePath("engine/ons/onsyuri"),
                defaultOnsyuriPath,
            ],
            named: "onsyuri"
        )
    }

    static func artemisExecutable() -> URL? {
        executable(
            configuredKey: "core.artemis.path",
            candidates: [
                projectPath("engine/ar/artemis-mac"),
                bundlePath("engine/ar/artemis-mac"),
                defaultArtemisPath,
            ],
            named: "artemis-mac"
        )
    }

    private static func executable(
        configuredKey: String,
        candidates: [String?],
        named name: String
    ) -> URL? {
        let configured = UserDefaults.standard.string(forKey: configuredKey) ?? ""
        let paths = ([configured] + candidates.compactMap { $0 }).filter { !$0.isEmpty }
        if let path = paths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: path)
        }
        return Bundle.main.url(forResource: name, withExtension: nil)
    }

    private static func projectPath(_ relativePath: String) -> String {
        projectRoot.appendingPathComponent(relativePath).path
    }

    private static func bundlePath(_ relativePath: String) -> String? {
        Bundle.main.resourceURL?.appendingPathComponent(relativePath).path
    }

    private static var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
