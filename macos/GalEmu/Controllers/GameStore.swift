import Foundation

enum GameStore {
    static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("GalEmu", isDirectory: true)
    }

    static var fileURL: URL {
        directoryURL.appendingPathComponent("games.json")
    }

    static func load() -> [Game]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        guard var games = try? JSONDecoder().decode([Game].self, from: data) else { return nil }

        if !UserDefaults.standard.bool(forKey: Keys.missingCleanupDone) {
            let before = games.count
            games.removeAll { !FileManager.default.fileExists(atPath: $0.metadata.directoryPath) }
            UserDefaults.standard.set(true, forKey: Keys.missingCleanupDone)
            if games.count != before {
                save(games)
            }
        }
        return games
    }

    static func save(_ games: [Game]) {
        let directory = directoryURL
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        guard let data = try? JSONEncoder().encode(games) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private enum Keys {
        static let missingCleanupDone = "library.missingCleanupDone"
    }
}
