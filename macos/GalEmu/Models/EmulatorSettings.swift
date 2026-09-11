import Combine
import Foundation

enum ScaleMode: String, CaseIterable, Identifiable {
    case aspectFit = "保持宽高比"
    case integer = "整数缩放"
    case stretch = "拉伸填充"

    var id: String { rawValue }
}

final class EmulatorSettings: ObservableObject {
    @Published var masterVolume: Double = 0.8 {
        didSet { defaults.set(masterVolume, forKey: Keys.masterVolume) }
    }

    @Published var bgmVolume: Double = 0.8 {
        didSet { defaults.set(bgmVolume, forKey: Keys.bgmVolume) }
    }

    @Published var seVolume: Double = 0.9 {
        didSet { defaults.set(seVolume, forKey: Keys.seVolume) }
    }

    @Published var voiceVolume: Double = 1.0 {
        didSet { defaults.set(voiceVolume, forKey: Keys.voiceVolume) }
    }

    @Published var scaleMode: ScaleMode = .aspectFit {
        didSet { defaults.set(scaleMode.rawValue, forKey: Keys.scaleMode) }
    }

    @Published var vsyncEnabled: Bool = true {
        didSet { defaults.set(vsyncEnabled, forKey: Keys.vsync) }
    }

    @Published var showPerformanceOverlay: Bool = false {
        didSet { defaults.set(showPerformanceOverlay, forKey: Keys.performanceOverlay) }
    }

    @Published var krkrsdl3Path: String = "" {
        didSet { defaults.set(krkrsdl3Path, forKey: Keys.krkrsdl3Path) }
    }

    private let defaults = UserDefaults.standard

    init() {
        masterVolume = defaults.object(forKey: Keys.masterVolume) as? Double ?? 0.8
        bgmVolume = defaults.object(forKey: Keys.bgmVolume) as? Double ?? 0.8
        seVolume = defaults.object(forKey: Keys.seVolume) as? Double ?? 0.9
        voiceVolume = defaults.object(forKey: Keys.voiceVolume) as? Double ?? 1.0
        scaleMode = ScaleMode(rawValue: defaults.string(forKey: Keys.scaleMode) ?? "") ?? .aspectFit
        vsyncEnabled = defaults.object(forKey: Keys.vsync) as? Bool ?? true
        showPerformanceOverlay = defaults.object(forKey: Keys.performanceOverlay) as? Bool ?? false
        krkrsdl3Path = defaults.string(forKey: Keys.krkrsdl3Path) ?? ""
    }

    private enum Keys {
        static let masterVolume = "audio.masterVolume"
        static let bgmVolume = "audio.bgmVolume"
        static let seVolume = "audio.seVolume"
        static let voiceVolume = "audio.voiceVolume"
        static let scaleMode = "video.scaleMode"
        static let vsync = "video.vsync"
        static let performanceOverlay = "debug.performanceOverlay"
        static let krkrsdl3Path = "core.krkrsdl3.path"
    }
}
