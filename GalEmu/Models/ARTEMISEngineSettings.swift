import Combine
import Foundation

enum ARTEMISPlatform: String, CaseIterable, Identifiable {
    case windows = "Windows"
    case android = "Android"

    var id: String { rawValue }

    var launchValue: String {
        switch self {
        case .windows:
            return "windows"
        case .android:
            return "android"
        }
    }
}

final class ARTEMISEngineSettings: ObservableObject {
    @Published var platform: ARTEMISPlatform = .windows {
        didSet { defaults.set(platform.rawValue, forKey: Keys.platform) }
    }

    private let defaults = UserDefaults.standard

    init() {
        SettingsMigration.runOnce()
        platform = ARTEMISPlatform(rawValue: defaults.string(forKey: Keys.platform) ?? "") ?? .windows
    }

    static func persistedLaunchArguments() -> [String] {
        let platform = ARTEMISPlatform(
            rawValue: UserDefaults.standard.string(forKey: Keys.platform) ?? ""
        ) ?? .windows
        return ["--os", platform.launchValue]
    }

    private enum Keys {
        static let platform = "engine.ar.platform"
    }
}
