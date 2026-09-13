import Foundation

enum AppIconLocator {
    static func iconURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            return url
        }
        guard let executableDir = Bundle.main.executableURL?.deletingLastPathComponent() else {
            return nil
        }
        let direct = executableDir.appendingPathComponent("\(name).png")
        if FileManager.default.fileExists(atPath: direct.path) {
            return direct
        }
        let resourceBundle = executableDir
            .appendingPathComponent("TyranorMac_TyranorMac.bundle")
            .appendingPathComponent("\(name).png")
        if FileManager.default.fileExists(atPath: resourceBundle.path) {
            return resourceBundle
        }
        return nil
    }
}
