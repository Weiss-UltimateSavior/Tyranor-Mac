import Combine
import Foundation

final class GameLibraryController: ObservableObject {
    @Published var games: [Game] {
        didSet { GameStore.save(games) }
    }

    @Published var selection: SidebarSelection = .home {
        didSet {
            if case .library(.all) = selection { return }
            searchText = ""
        }
    }

    @Published var searchText = ""

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
        SettingsMigration.runOnce()
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
        var result = games.filter { matches($0, filter: filter) }
        if filter == .all, !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.metadata.developer.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted(by: orderedBefore)
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

    func setCover(
        for gameID: UUID,
        path: String,
        source: CoverSource,
        metadata: CoverMetadata? = nil
    ) {
        guard let index = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[index].coverPath = path
        games[index].coverSource = source

        if let metadata {
            if let originalTitle = metadata.originalTitle, !originalTitle.isEmpty {
                games[index].metadata.originalTitle = originalTitle
            }
            if let developer = metadata.developer, !developer.isEmpty {
                games[index].metadata.developer = developer
            }
            if let releaseDate = metadata.releaseDate, !releaseDate.isEmpty {
                games[index].metadata.releaseDate = releaseDate
                if let year = Int(releaseDate.prefix(4)) {
                    games[index].metadata.releaseYear = year
                }
            }
            if let summary = metadata.summary, !summary.isEmpty {
                games[index].metadata.summary = summary
            }
            if !metadata.tags.isEmpty {
                games[index].metadata.tags = Array(metadata.tags.prefix(8))
            }
        }
    }

    func remove(_ game: Game) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games.remove(at: index)
        if selectedGameID == game.id {
            selectedGameID = games.first?.id
        }
    }

    func rename(_ game: Game, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].title = trimmed
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
