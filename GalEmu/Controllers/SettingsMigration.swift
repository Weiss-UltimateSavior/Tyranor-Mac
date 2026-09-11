import Foundation

enum SettingsMigration {
    private static let lock = NSLock()
    private static var didRun = false

    static func runOnce() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRun else { return }
        didRun = true

        let defaults = UserDefaults.standard
        guard let legacy = defaults.persistentDomain(forName: "GalEmu") else { return }
        for (key, value) in legacy where !key.hasPrefix("NSWindow Frame") {
            if defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
    }
}
