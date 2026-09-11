import Combine
import Foundation

final class GameLibraryController: ObservableObject {
    @Published var games: [Game] {
        didSet { GameStore.save(games) }
    }

    @Published var selection: SidebarSelection = .home

    @Published var sort: LibrarySort {
        didSet { UserDefaults.standard.set(sort.rawValue, forKey: Keys.sort) }
    }

    @Published var selectedGameID: Game.ID?

    var filter: LibraryFilter {
        if case let .library(filter) = selection {
            return filter
        }
        return .all
    }

    init() {
        let loaded = GameStore.load() ?? []
        games = loaded
        sort = LibrarySort(rawValue: UserDefaults.standard.string(forKey: Keys.sort) ?? "") ?? .recentlyPlayed
        selectedGameID = loaded.first?.id
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

    func markPlayed(_ game: Game) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].lastPlayed = Date()
    }

    func setCover(for gameID: UUID, path: String, source: CoverSource) {
        guard let index = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[index].coverPath = path
        games[index].coverSource = source
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
        case let .engine(engine):
            return game.engine == engine
        case let .developer(developer):
            return game.metadata.developer == developer
        }
    }

    private func orderedBefore(_ lhs: Game, _ rhs: Game) -> Bool {
        switch sort {
        case .recentlyPlayed:
            let lhsDate = lhs.lastPlayed ?? .distantPast
            let rhsDate = rhs.lastPlayed ?? .distantPast
            if lhsDate == rhsDate {
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
            return lhsDate > rhsDate
        case .title:
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private enum Keys {
        static let sort = "library.sort"
    }
}
