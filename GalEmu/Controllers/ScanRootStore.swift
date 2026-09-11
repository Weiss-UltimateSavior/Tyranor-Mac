import Foundation

enum ScanRootStore {
    private static let key = "scan.roots"
    private static let limit = 10

    static func load() -> [URL] {
        (UserDefaults.standard.stringArray(forKey: key) ?? [])
            .map { URL(fileURLWithPath: $0) }
    }

    static func add(_ url: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: key) ?? []
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > limit {
            paths.removeLast(paths.count - limit)
        }
        UserDefaults.standard.set(paths, forKey: key)
    }
}
