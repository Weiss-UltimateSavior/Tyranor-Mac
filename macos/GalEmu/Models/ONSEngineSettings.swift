import Combine
import Foundation

enum ONSTextEncoding: String, CaseIterable, Identifiable {
    case automatic = "默认"
    case sjis = "Shift-JIS"
    case gbk = "GBK"
    case utf8 = "UTF-8"

    var id: String { rawValue }

    var launchValue: String? {
        switch self {
        case .automatic:
            return nil
        case .sjis:
            return "-enc:sjis"
        case .gbk:
            return "-enc:gbk"
        case .utf8:
            return "-enc:utf8"
        }
    }
}

enum ONSWindowSize: String, CaseIterable, Identifiable {
    case automatic = "默认"
    case vga = "800 × 600"
    case hd = "1280 × 720"
    case fhd = "1920 × 1080"

    var id: String { rawValue }

    var launchValues: [String] {
        switch self {
        case .automatic:
            return []
        case .vga:
            return ["--width", "800", "--height", "600"]
        case .hd:
            return ["--width", "1280", "--height", "720"]
        case .fhd:
            return ["--width", "1920", "--height", "1080"]
        }
    }
}

final class ONSEngineSettings: ObservableObject {
    @Published var encoding: ONSTextEncoding = .automatic {
        didSet { defaults.set(encoding.rawValue, forKey: Keys.encoding) }
    }

    @Published var windowSize: ONSWindowSize = .automatic {
        didSet { defaults.set(windowSize.rawValue, forKey: Keys.windowSize) }
    }

    @Published var fullscreen: Bool = false {
        didSet { defaults.set(fullscreen, forKey: Keys.fullscreen) }
    }

    @Published var disableVideo: Bool = false {
        didSet { defaults.set(disableVideo, forKey: Keys.disableVideo) }
    }

    @Published var wheelDownAdvance: Bool = false {
        didSet { defaults.set(wheelDownAdvance, forKey: Keys.wheelDownAdvance) }
    }

    private let defaults = UserDefaults.standard

    init() {
        SettingsMigration.runOnce()
        encoding = ONSTextEncoding(rawValue: defaults.string(forKey: Keys.encoding) ?? "") ?? .automatic
        windowSize = ONSWindowSize(rawValue: defaults.string(forKey: Keys.windowSize) ?? "") ?? .automatic
        fullscreen = defaults.object(forKey: Keys.fullscreen) as? Bool ?? false
        disableVideo = defaults.object(forKey: Keys.disableVideo) as? Bool ?? false
        wheelDownAdvance = defaults.object(forKey: Keys.wheelDownAdvance) as? Bool ?? false
    }

    static func persistedLaunchArguments() -> [String] {
        let encoding = ONSTextEncoding(rawValue: UserDefaults.standard.string(forKey: Keys.encoding) ?? "") ?? .automatic
        let windowSize = ONSWindowSize(rawValue: UserDefaults.standard.string(forKey: Keys.windowSize) ?? "") ?? .automatic
        let fullscreen = UserDefaults.standard.object(forKey: Keys.fullscreen) as? Bool ?? false
        let disableVideo = UserDefaults.standard.object(forKey: Keys.disableVideo) as? Bool ?? false
        let wheelDownAdvance = UserDefaults.standard.object(forKey: Keys.wheelDownAdvance) as? Bool ?? false

        var arguments: [String] = []
        if let value = encoding.launchValue {
            arguments.append(value)
        }
        arguments.append(contentsOf: windowSize.launchValues)
        if fullscreen {
            arguments.append("--fullscreen")
        }
        if disableVideo {
            arguments.append("--no-video")
        }
        if wheelDownAdvance {
            arguments.append("--enable-wheeldown-advance")
        }
        let vsync = UserDefaults.standard.object(forKey: Keys.vsync) as? Bool ?? true
        if !vsync {
            arguments.append("--no-vsync")
        }
        return arguments
    }

    private enum Keys {
        static let encoding = "engine.ons.encoding"
        static let windowSize = "engine.ons.windowSize"
        static let fullscreen = "engine.ons.fullscreen"
        static let disableVideo = "engine.ons.disableVideo"
        static let wheelDownAdvance = "engine.ons.wheelDownAdvance"
        static let vsync = "video.vsync"
    }
}
