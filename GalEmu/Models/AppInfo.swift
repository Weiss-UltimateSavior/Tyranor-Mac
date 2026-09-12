import Foundation

enum AppInfo {
    static let repository = "Weiss-UltimateSavior/Tyranor-Mac"
    static let fallbackVersion = "0.1.0"

    static var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !version.isEmpty {
            return version
        }
        return fallbackVersion
    }
}
