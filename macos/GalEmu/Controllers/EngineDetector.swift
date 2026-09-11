import Foundation

enum EngineDetector {
    struct Detection {
        let engine: EngineKind
        let confidence: Int
    }

    private struct Entry {
        let url: URL
        let name: String
        let isDirectory: Bool
    }

    private struct Flags {
        var xp3Files: [String] = []
        var hasStartupTjs = false
        var hasConfigTjs = false
        var hasBootIni = false
        var hasSystemIni = false
        var hasFirstIet = false
        var hasRootPfs = false
        var hasPatchPfs = false
        var hasAnyPfs = false
        var hasObbLikeFile = false
        var hasOnsScript = false
        var hasOnsArchive = false
    }

    private static let searchDirectoryNames: Set<String> = [
        "data", "tyrano", "scenario", "system", "app", "game",
        "renpy", "resources", "app.asar", "www", "js",
    ]

    private static let pfsPatchPattern = #"^[^.]+\.pfs\.\d{3}$"#
    private static let obbPattern = #"^(main|patch)\.\d+\..+\.obb$"#

    static func detect(directory: URL) -> Detection? {
        var flags = Flags()
        for entry in contents(of: directory) {
            collect(entry, relativePath: "", into: &flags)
        }
        return detection(from: flags)
    }

    private static func collect(_ entry: Entry, relativePath: String, into flags: inout Flags) {
        let lower = entry.name.lowercased()
        guard !lower.isEmpty else { return }
        let childPath = relativePath.isEmpty ? lower : "\(relativePath)/\(lower)"

        if entry.isDirectory {
            if searchDirectoryNames.contains(lower) {
                for child in contents(of: entry.url) {
                    collect(child, relativePath: childPath, into: &flags)
                }
            }
            return
        }

        if lower == "startup.tjs" {
            flags.hasStartupTjs = true
        } else if lower == "config.tjs" {
            flags.hasConfigTjs = true
        } else if lower == "boot.ini" {
            flags.hasBootIni = true
        } else if lower == "system.ini" {
            flags.hasSystemIni = true
        } else if childPath == "system/first.iet" || childPath.hasSuffix("/system/first.iet") {
            flags.hasFirstIet = true
        } else if lower == "root.pfs" {
            flags.hasRootPfs = true
        } else if matches(pfsPatchPattern, lower) {
            flags.hasPatchPfs = true
        } else if lower.hasSuffix(".pfs") {
            flags.hasAnyPfs = true
        } else if lower.hasSuffix(".obb") || matches(obbPattern, lower) {
            flags.hasObbLikeFile = true
        } else if lower == "0.txt" || lower == "00.txt" || lower == "nscript.dat"
            || lower == "onscript.nt2" || lower == "onscript.nt3" {
            flags.hasOnsScript = true
        } else if lower.hasSuffix(".nsa") || lower.hasSuffix(".sar") {
            flags.hasOnsArchive = true
        } else if lower.hasSuffix(".xp3") {
            flags.xp3Files.append(childPath)
        }
    }

    private static func detection(from flags: Flags) -> Detection? {
        if (flags.hasSystemIni && flags.hasFirstIet) || flags.hasRootPfs
            || flags.hasPatchPfs || flags.hasAnyPfs || (flags.hasBootIni && flags.hasObbLikeFile) {
            let highConfidence = (flags.hasSystemIni && flags.hasFirstIet) || flags.hasRootPfs
                || (flags.hasBootIni && flags.hasObbLikeFile)
            return Detection(engine: .artemis, confidence: highConfidence ? 95 : 90)
        }

        if !flags.xp3Files.isEmpty || flags.hasStartupTjs || flags.hasConfigTjs {
            return Detection(engine: .kirikiri, confidence: flags.xp3Files.isEmpty ? 80 : 95)
        }

        if flags.hasOnsScript || flags.hasOnsArchive {
            return Detection(engine: .ons, confidence: flags.hasOnsScript ? 90 : 70)
        }

        return nil
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func contents(of directory: URL) -> [Entry] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls.map { url in
            Entry(
                url: url,
                name: url.lastPathComponent,
                isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            )
        }
    }

    static func scanGames(in directory: URL, maxDepth: Int = 3) -> [Game] {
        var results: [Game] = []
        traverse(directory, level: 0, maxDepth: maxDepth, results: &results)
        return results
    }

    static func kirikiriLaunchEntry(in directory: URL) -> URL {
        let preferred = [
            "data.xp3", "main.xp3", "scn.xp3", "patch.xp3", "scenario.xp3",
            "startup.tjs", "0.ebk",
        ]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        if let startup = files.first(where: { $0.lastPathComponent.lowercased() == "startup.tjs" }) {
            return startup
        }

        let xp3Files = files.filter {
            let lower = $0.lastPathComponent.lowercased()
            return lower.hasSuffix(".xp3") && !lower.hasPrefix("bg")
        }

        if let boot = xp3Files.first(where: { XP3Archive.containsRootStartupScript(at: $0) }) {
            return boot
        }

        for name in preferred {
            if let match = files.first(where: { $0.lastPathComponent.lowercased() == name }) {
                return match
            }
        }

        return xp3Files.first ?? directory
    }

    private static func traverse(_ directory: URL, level: Int, maxDepth: Int, results: inout [Game]) {
        guard level <= maxDepth else { return }

        if let detection = detect(directory: directory) {
            results.append(game(for: directory, detection: detection))
            return
        }

        for child in subdirectories(of: directory) {
            traverse(child, level: level + 1, maxDepth: maxDepth, results: &results)
        }
    }

    private static func game(for directory: URL, detection: Detection) -> Game {
        let coverPath = CoverSupport.localCoverPath(in: directory)
        return Game(
            title: directory.lastPathComponent,
            metadata: GameMetadata(
                developer: "未知",
                releaseYear: Calendar.current.component(.year, from: Date()),
                summary: "扫描发现的本地游戏目录。",
                tags: [],
                directoryPath: directory.path
            ),
            engine: detection.engine,
            coverPath: coverPath,
            coverSource: coverPath == nil ? nil : .local,
            lastPlayed: nil
        )
    }

    private static func subdirectories(of directory: URL) -> [URL] {
        contents(of: directory)
            .filter(\.isDirectory)
            .map(\.url)
    }
}
