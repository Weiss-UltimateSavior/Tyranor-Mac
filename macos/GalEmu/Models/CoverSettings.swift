import Combine
import Foundation

final class CoverSettings: ObservableObject {
    @Published var onlyMissing: Bool = true {
        didSet { defaults.set(onlyMissing, forKey: Keys.onlyMissing) }
    }

    @Published var useVNDB: Bool = true {
        didSet { defaults.set(useVNDB, forKey: Keys.useVNDB) }
    }

    @Published var useBangumi: Bool = true {
        didSet { defaults.set(useBangumi, forKey: Keys.useBangumi) }
    }

    @Published var useSteam: Bool = true {
        didSet { defaults.set(useSteam, forKey: Keys.useSteam) }
    }

    private let defaults = UserDefaults.standard

    init() {
        onlyMissing = defaults.object(forKey: Keys.onlyMissing) as? Bool ?? true
        useVNDB = defaults.object(forKey: Keys.useVNDB) as? Bool ?? true
        useBangumi = defaults.object(forKey: Keys.useBangumi) as? Bool ?? true
        useSteam = defaults.object(forKey: Keys.useSteam) as? Bool ?? true
    }

    var enabledSources: [CoverSource] {
        var sources: [CoverSource] = []
        if useVNDB { sources.append(.vndb) }
        if useBangumi { sources.append(.bangumi) }
        if useSteam { sources.append(.steam) }
        return sources
    }

    private enum Keys {
        static let onlyMissing = "cover.onlyMissing"
        static let useVNDB = "cover.useVNDB"
        static let useBangumi = "cover.useBangumi"
        static let useSteam = "cover.useSteam"
    }
}
