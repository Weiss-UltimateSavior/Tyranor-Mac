import Foundation

enum CoreLocator {
    static let defaultKrkrsdl3Path = "/Users/weiss/opencode/krkrsdl3_build/out/macos/Release/krkrsdl3"
    static let defaultOnsyuriPath = "/Users/weiss/github- engine/OnscripterYuri/build_darwin/onsyuri"

    static func krkrsdl3Executable() -> URL? {
        executable(configuredKey: "core.krkrsdl3.path", defaultPath: defaultKrkrsdl3Path, named: "krkrsdl3")
    }

    static func onsyuriExecutable() -> URL? {
        executable(configuredKey: "core.onsyuri.path", defaultPath: defaultOnsyuriPath, named: "onsyuri")
    }

    private static func executable(configuredKey: String, defaultPath: String, named name: String) -> URL? {
        let configured = UserDefaults.standard.string(forKey: configuredKey) ?? ""
        let candidates = [configured, defaultPath].filter { !$0.isEmpty }
        if let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: path)
        }
        return Bundle.main.url(forResource: name, withExtension: nil)
    }
}
