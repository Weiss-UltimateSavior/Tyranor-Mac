import Foundation

enum EngineKind: String, CaseIterable, Identifiable, Codable {
    case kirikiri = "KIRIKIRI"
    case artemis = "ARTEMIS"
    case ons = "ONS"

    var id: String { rawValue }
}

enum PlayStatus: String, CaseIterable, Identifiable, Codable {
    case notStarted = "未游玩"
    case playing = "游玩中"
    case completed = "已完成"

    var id: String { rawValue }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case recentlyPlayed = "最近游玩"
    case title = "名称"
    case playtime = "游玩时长"

    var id: String { rawValue }
}

enum LibraryFilter: Hashable {
    case all
    case favorites
    case recent
    case status(PlayStatus)
    case engine(EngineKind)
    case developer(String)
}

struct Game: Identifiable, Hashable {
    let id: UUID
    var title: String
    var metadata: GameMetadata
    var engine: EngineKind
    var status: PlayStatus
    var isFavorite: Bool
    var isLocked: Bool
    var hasTrailer: Bool
    var playtimeHours: Double
    var lastPlayed: Date?

    init(
        id: UUID = UUID(),
        title: String,
        metadata: GameMetadata,
        engine: EngineKind,
        status: PlayStatus,
        isFavorite: Bool = false,
        isLocked: Bool = false,
        hasTrailer: Bool = false,
        playtimeHours: Double = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.metadata = metadata
        self.engine = engine
        self.status = status
        self.isFavorite = isFavorite
        self.isLocked = isLocked
        self.hasTrailer = hasTrailer
        self.playtimeHours = playtimeHours
        self.lastPlayed = lastPlayed
    }
}
