import Foundation

enum EngineKind: String, CaseIterable, Identifiable, Codable {
    case kirikiri = "KIRIKIRI"
    case artemis = "ARTEMIS"
    case ons = "ONS"

    var id: String { rawValue }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case recentlyPlayed = "最近游玩"
    case title = "名称"

    var id: String { rawValue }
}

enum LibraryFilter: Hashable {
    case all
    case favorites
    case recent
    case engine(EngineKind)
    case developer(String)
}

enum SidebarSelection: Hashable {
    case home
    case library(LibraryFilter)
    case engine(EngineKind)
}

enum CoverSource: String, Codable, CaseIterable, Identifiable {
    case local
    case vndb
    case bangumi
    case steam
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:
            return "本地"
        case .vndb:
            return "VNDB"
        case .bangumi:
            return "Bangumi"
        case .steam:
            return "Steam"
        case .custom:
            return "自定义"
        }
    }
}

struct Game: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var metadata: GameMetadata
    var engine: EngineKind
    var coverPath: String?
    var coverSource: CoverSource?
    var isFavorite: Bool
    var lastPlayed: Date?

    init(
        id: UUID = UUID(),
        title: String,
        metadata: GameMetadata,
        engine: EngineKind,
        coverPath: String? = nil,
        coverSource: CoverSource? = nil,
        isFavorite: Bool = false,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.metadata = metadata
        self.engine = engine
        self.coverPath = coverPath
        self.coverSource = coverSource
        self.isFavorite = isFavorite
        self.lastPlayed = lastPlayed
    }
}
