import Combine
import Foundation

@MainActor
final class CoverScraper: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentTitle = ""
    @Published private(set) var updatedCount = 0
    @Published private(set) var skippedCount = 0
    @Published private(set) var failedCount = 0

    private var cancelRequested = false

    func cancel() {
        cancelRequested = true
    }

    func scrape(games: [Game], settings: CoverSettings, apply: @escaping (UUID, String, CoverSource) -> Void) {
        guard !isRunning else { return }
        startRun()

        Task {
            let total = max(games.count, 1)
            for (index, game) in games.enumerated() {
                if cancelRequested { break }
                progress = Double(index) / Double(total)
                currentTitle = game.title

                if let cover = await Self.resolveCover(for: game, settings: settings) {
                    if cover.path == game.coverPath, cover.source == game.coverSource {
                        skippedCount += 1
                    } else {
                        apply(game.id, cover.path, cover.source)
                        updatedCount += 1
                    }
                } else if game.coverPath != nil {
                    skippedCount += 1
                } else {
                    failedCount += 1
                }
            }
            finishRun()
        }
    }

    func fetchSingle(_ game: Game, settings: CoverSettings, apply: @escaping (UUID, String, CoverSource) -> Void) {
        guard !isRunning else { return }
        startRun()
        currentTitle = game.title

        Task {
            if let cover = await Self.resolveCover(for: game, settings: settings) {
                if cover.path == game.coverPath, cover.source == game.coverSource {
                    skippedCount = 1
                } else {
                    apply(game.id, cover.path, cover.source)
                    updatedCount = 1
                }
            } else {
                failedCount = 1
            }
            finishRun()
        }
    }

    static func resolveCover(for game: Game, settings: CoverSettings) async -> (path: String, source: CoverSource)? {
        let directory = URL(fileURLWithPath: game.metadata.directoryPath)
        let localPath = CoverSupport.localCoverPath(in: directory)
        let local = localPath.map { ($0, CoverSource.local) }

        if settings.onlyMissing {
            if let local { return local }
            if let existing = game.coverPath, FileManager.default.fileExists(atPath: existing) {
                return nil
            }
        }

        let query = CoverSupport.cleanTitle(game.title)
        guard !query.isEmpty else { return local }

        let key = CoverSupport.stableKey(game.metadata.directoryPath)
        for source in settings.enabledSources {
            let candidates = await CoverServices.candidates(query: query, source: source)
            for candidate in candidates {
                if let path = await CoverImageCache.download(
                    url: candidate.url,
                    prefix: "\(source.rawValue)_\(key)",
                    source: source
                ) {
                    return (path, source)
                }
            }
        }
        return local
    }

    private func startRun() {
        isRunning = true
        cancelRequested = false
        progress = 0
        currentTitle = ""
        updatedCount = 0
        skippedCount = 0
        failedCount = 0
    }

    private func finishRun() {
        progress = 1
        currentTitle = ""
        isRunning = false
    }
}
