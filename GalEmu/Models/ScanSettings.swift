import Combine
import Foundation

final class ScanSettings: ObservableObject {
    @Published var maxDepth: Int = 3 {
        didSet { defaults.set(maxDepth, forKey: Keys.maxDepth) }
    }

    private let defaults = UserDefaults.standard

    init() {
        SettingsMigration.runOnce()
        let stored = defaults.object(forKey: Keys.maxDepth) as? Int ?? 3
        maxDepth = min(max(stored, 1), 8)
    }

    private enum Keys {
        static let maxDepth = "scan.maxDepth"
    }
}
