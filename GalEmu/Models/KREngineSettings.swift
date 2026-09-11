import Combine
import Foundation

enum RendererOption: String, CaseIterable, Identifiable {
    case automatic = "默认"
    case opengl = "OpenGL"
    case software = "软件渲染"

    var id: String { rawValue }

    var launchValue: String? {
        switch self {
        case .automatic:
            return nil
        case .opengl:
            return "opengl"
        case .software:
            return "software"
        }
    }
}

enum WindowSizeOption: String, CaseIterable, Identifiable {
    case automatic = "默认"
    case hd720 = "1280 × 720"
    case hd900 = "1600 × 900"
    case fhd1080 = "1920 × 1080"
    case qhd1440 = "2560 × 1440"

    var id: String { rawValue }

    var launchValue: String? {
        switch self {
        case .automatic:
            return nil
        case .hd720:
            return "1280x720"
        case .hd900:
            return "1600x900"
        case .fhd1080:
            return "1920x1080"
        case .qhd1440:
            return "2560x1440"
        }
    }
}

final class KREngineSettings: ObservableObject {
    @Published var renderer: RendererOption = .automatic {
        didSet { defaults.set(renderer.rawValue, forKey: Keys.renderer) }
    }

    @Published var windowSize: WindowSizeOption = .automatic {
        didSet { defaults.set(windowSize.rawValue, forKey: Keys.windowSize) }
    }

    private let defaults = UserDefaults.standard

    init() {
        SettingsMigration.runOnce()
        renderer = RendererOption(rawValue: defaults.string(forKey: Keys.renderer) ?? "") ?? .automatic
        windowSize = WindowSizeOption(rawValue: defaults.string(forKey: Keys.windowSize) ?? "") ?? .automatic
    }

    func launchArguments() -> [String] {
        Self.persistedLaunchArguments()
    }

    static func persistedLaunchArguments() -> [String] {
        let renderer = RendererOption(rawValue: UserDefaults.standard.string(forKey: Keys.renderer) ?? "") ?? .automatic
        let windowSize = WindowSizeOption(rawValue: UserDefaults.standard.string(forKey: Keys.windowSize) ?? "") ?? .automatic
        let vsync = UserDefaults.standard.object(forKey: Keys.vsync) as? Bool ?? true

        var arguments: [String] = []
        if let value = renderer.launchValue {
            arguments.append("-render=\(value)")
        }
        if let value = windowSize.launchValue {
            arguments.append("-window=\(value)")
        }
        arguments.append("-vsync=\(vsync ? 1 : 0)")
        return arguments
    }

    private enum Keys {
        static let renderer = "engine.kr.renderer"
        static let windowSize = "engine.kr.windowSize"
        static let vsync = "video.vsync"
    }
}
