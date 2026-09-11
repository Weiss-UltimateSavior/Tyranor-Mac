import Combine
import Foundation

final class GameLibraryController: ObservableObject {
    @Published var games: [Game]
    @Published var filter: LibraryFilter = .all
    @Published var sort: LibrarySort = .recentlyPlayed
    @Published var selectedGameID: Game.ID?

    init(games: [Game] = Game.samples) {
        self.games = games
        self.selectedGameID = games.first?.id
    }

    var selectedGame: Game? {
        guard let selectedGameID else { return nil }
        return games.first { $0.id == selectedGameID }
    }

    var visibleGames: [Game] {
        games
            .filter { matches($0, filter: filter) }
            .sorted(by: orderedBefore)
    }

    func count(for filter: LibraryFilter) -> Int {
        games.filter { matches($0, filter: filter) }.count
    }

    func select(_ game: Game) {
        selectedGameID = game.id
    }

    func toggleFavorite(_ game: Game) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].isFavorite.toggle()
    }

    func add(_ newGames: [Game]) {
        let existingPaths = Set(games.map(\.metadata.directoryPath))
        let unique = newGames.filter { !existingPaths.contains($0.metadata.directoryPath) }
        guard !unique.isEmpty else { return }
        games.append(contentsOf: unique)
        selectedGameID = unique.first?.id
    }

    private func matches(_ game: Game, filter: LibraryFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .favorites:
            return game.isFavorite
        case .recent:
            return game.lastPlayed != nil
        case let .status(status):
            return game.status == status
        case let .engine(engine):
            return game.engine == engine
        case let .developer(developer):
            return game.metadata.developer == developer
        }
    }

    private func orderedBefore(_ lhs: Game, _ rhs: Game) -> Bool {
        switch sort {
        case .recentlyPlayed:
            return (lhs.lastPlayed ?? .distantPast) > (rhs.lastPlayed ?? .distantPast)
        case .title:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        case .playtime:
            return lhs.playtimeHours > rhs.playtimeHours
        }
    }
}

private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
}

extension Game {
    static let samples: [Game] = [
        Game(
            title: "千恋＊万花",
            metadata: GameMetadata(
                developer: "Yuzusoft",
                releaseYear: 2016,
                summary: "被刀「丛雨丸」选中的少年，在温泉小镇建实町与四位少女相遇。柚子社和风代表作，四季流转中的羁绊与宿命。",
                tags: ["和风", "恋爱", "废萌"],
                directoryPath: "/Users/Shared/Galgame/SenrenBanka"
            ),
            engine: .kirikiri,
            status: .completed,
            isFavorite: true,
            hasTrailer: true,
            playtimeHours: 38,
            lastPlayed: daysAgo(0)
        ),
        Game(
            title: "ATRI -My Dear Moments-",
            metadata: GameMetadata(
                developer: "Frontwing",
                releaseYear: 2020,
                summary: "在海边小镇苏醒的少年与机器人少女 ATRI，一段关于心与眼泪的夏日物语。",
                tags: ["科幻", "催泪"],
                directoryPath: "/Users/Shared/Galgame/ATRI"
            ),
            engine: .kirikiri,
            status: .completed,
            isFavorite: true,
            playtimeHours: 15,
            lastPlayed: daysAgo(2)
        ),
        Game(
            title: "9-nine-雪色雪花雪之痕",
            metadata: GameMetadata(
                developer: "palette",
                releaseYear: 2021,
                summary: "围绕圣遗物展开的都市异能系列第四部，白蛇与少女们的最终篇章。",
                tags: ["异能", "悬疑"],
                directoryPath: "/Users/Shared/Galgame/9nine-4"
            ),
            engine: .kirikiri,
            status: .playing,
            playtimeHours: 12,
            lastPlayed: daysAgo(1)
        ),
        Game(
            title: "RIDDLE JOKER",
            metadata: GameMetadata(
                developer: "Yuzusoft",
                releaseYear: 2018,
                summary: "以超能力者学园为舞台，柚子社正统派恋爱喜剧。",
                tags: ["学园", "恋爱"],
                directoryPath: "/Users/Shared/Galgame/RiddleJoker"
            ),
            engine: .kirikiri,
            status: .completed,
            playtimeHours: 30,
            lastPlayed: daysAgo(5)
        ),
        Game(
            title: "缘之空",
            metadata: GameMetadata(
                developer: "Sphere",
                releaseYear: 2008,
                summary: "远离都市的乡村小镇，悠与穹的双子物语。",
                tags: ["乡村", "经典"],
                directoryPath: "/Users/Shared/Galgame/Yosuga"
            ),
            engine: .artemis,
            status: .notStarted,
            isLocked: true,
            hasTrailer: true
        ),
        Game(
            title: "Summer Pockets",
            metadata: GameMetadata(
                developer: "Key",
                releaseYear: 2018,
                summary: "在离岛度过的暑假，少年与少女们短暂而耀眼的夏日记忆。",
                tags: ["夏日", "催泪"],
                directoryPath: "/Users/Shared/Galgame/SummerPockets"
            ),
            engine: .kirikiri,
            status: .completed,
            isFavorite: true,
            playtimeHours: 26,
            lastPlayed: daysAgo(20)
        ),
        Game(
            title: "1room -家出少女-",
            metadata: GameMetadata(
                developer: "Tigoris",
                releaseYear: 2018,
                summary: "与离家出走的少女同住一个屋檐下的日常物语。",
                tags: ["日常"],
                directoryPath: "/Users/Shared/Galgame/1room"
            ),
            engine: .ons,
            status: .notStarted,
            isLocked: true
        ),
        Game(
            title: "LOVEPICAL-POPPY!",
            metadata: GameMetadata(
                developer: "SAGA PLANETS",
                releaseYear: 2020,
                summary: "为了寻找恋爱的意义，少年加入了恋爱研究部。",
                tags: ["学园", "喜剧"],
                directoryPath: "/Users/Shared/Galgame/LovePical"
            ),
            engine: .artemis,
            status: .playing,
            playtimeHours: 8,
            lastPlayed: daysAgo(3)
        ),
        Game(
            title: "タユタマ2 -You're the only one-",
            metadata: GameMetadata(
                developer: "Lump of Sugar",
                releaseYear: 2016,
                summary: "继承了妖怪之力的少年与兽耳少女们的同居生活。",
                tags: ["兽耳", "奇幻"],
                directoryPath: "/Users/Shared/Galgame/Tayutama2"
            ),
            engine: .kirikiri,
            status: .playing,
            playtimeHours: 6,
            lastPlayed: daysAgo(4)
        ),
    ]
}
