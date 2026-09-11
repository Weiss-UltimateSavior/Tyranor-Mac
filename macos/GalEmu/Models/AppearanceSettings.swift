import AppKit
import Combine
import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

enum AccentPalette: String, CaseIterable, Identifiable {
    case blue = "蓝色"
    case purple = "紫色"
    case pink = "粉色"
    case green = "绿色"
    case orange = "橙色"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue:
            return Color(red: 0.294, green: 0.463, blue: 0.949)
        case .purple:
            return Color(red: 0.545, green: 0.396, blue: 0.949)
        case .pink:
            return Color(red: 0.937, green: 0.357, blue: 0.557)
        case .green:
            return Color(red: 0.239, green: 0.702, blue: 0.478)
        case .orange:
            return Color(red: 0.945, green: 0.573, blue: 0.243)
        }
    }
}

enum CoverSize: String, CaseIterable, Identifiable {
    case compact = "紧凑"
    case standard = "标准"
    case large = "宽松"

    var id: String { rawValue }

    var columnWidth: (min: CGFloat, max: CGFloat) {
        switch self {
        case .compact:
            return (120, 150)
        case .standard:
            return (150, 190)
        case .large:
            return (190, 240)
        }
    }
}

enum CoverCorner: String, CaseIterable, Identifiable {
    case small = "小"
    case medium = "中"
    case large = "大"

    var id: String { rawValue }

    var radius: CGFloat {
        switch self {
        case .small:
            return 6
        case .medium:
            return 10
        case .large:
            return 16
        }
    }
}

final class AppearanceSettings: ObservableObject {
    @Published var themeMode: ThemeMode = .system {
        didSet {
            defaults.set(themeMode.rawValue, forKey: Keys.themeMode)
            applyThemeMode()
        }
    }

    @Published var accent: AccentPalette = .blue {
        didSet { defaults.set(accent.rawValue, forKey: Keys.accent) }
    }

    @Published var coverSize: CoverSize = .standard {
        didSet { defaults.set(coverSize.rawValue, forKey: Keys.coverSize) }
    }

    @Published var coverCorner: CoverCorner = .medium {
        didSet { defaults.set(coverCorner.rawValue, forKey: Keys.coverCorner) }
    }

    private let defaults = UserDefaults.standard

    init() {
        SettingsMigration.runOnce()
        themeMode = ThemeMode(rawValue: defaults.string(forKey: Keys.themeMode) ?? "") ?? .system
        accent = AccentPalette(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .blue
        coverSize = CoverSize(rawValue: defaults.string(forKey: Keys.coverSize) ?? "") ?? .standard
        coverCorner = CoverCorner(rawValue: defaults.string(forKey: Keys.coverCorner) ?? "") ?? .medium
        DispatchQueue.main.async { [weak self] in
            self?.applyThemeMode()
        }
    }

    private func applyThemeMode() {
        NSApp?.appearance = themeMode.appearance
    }

    private enum Keys {
        static let themeMode = "appearance.themeMode"
        static let accent = "appearance.accent"
        static let coverSize = "appearance.coverSize"
        static let coverCorner = "appearance.coverCorner"
    }
}
