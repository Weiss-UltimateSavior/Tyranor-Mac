import Foundation

struct SaveFileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let modified: Date

    var name: String { url.lastPathComponent }

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: modified)
    }
}

enum SaveManagerError: LocalizedError {
    case nothingToExport
    case invalidArchive
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .nothingToExport:
            return "没有可导出的存档"
        case .invalidArchive:
            return "存档包无效或不包含文件"
        case let .commandFailed(message):
            return message
        }
    }
}

enum SaveManager {
    static func saveDirectory(for game: Game) -> URL {
        let root = URL(fileURLWithPath: game.metadata.directoryPath)
        switch game.engine {
        case .kirikiri:
            return root.appendingPathComponent("savedata", isDirectory: true)
        case .ons:
            return root.appendingPathComponent("save", isDirectory: true)
        case .artemis:
            return root
        }
    }

    static func files(for game: Game) -> [SaveFileInfo] {
        let directory = saveDirectory(for: game)
        guard FileManager.default.fileExists(atPath: directory.path),
              let enumerator = FileManager.default.enumerator(
                  at: directory,
                  includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                  options: [.skipsHiddenFiles]
              ) else { return [] }

        var infos: [SaveFileInfo] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            infos.append(
                SaveFileInfo(
                    url: url,
                    size: Int64(values?.fileSize ?? 0),
                    modified: values?.contentModificationDate ?? .distantPast
                )
            )
        }
        return infos.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func export(game: Game, to destination: URL) throws {
        guard !files(for: game).isEmpty else { throw SaveManagerError.nothingToExport }
        let directory = saveDirectory(for: game)

        let temporary = destination
            .deletingLastPathComponent()
            .appendingPathComponent(".\(destination.lastPathComponent).tmp-\(UUID().uuidString)")
        try runDitto(["-c", "-k", "--norsrc", "--noextattr", directory.path, temporary.path])
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
    }

    static func importZip(game: Game, from source: URL) throws {
        let directory = saveDirectory(for: game)
        let parent = directory.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

        let staging = parent.appendingPathComponent("\(directory.lastPathComponent).import-staging-\(UUID().uuidString)")
        try? FileManager.default.removeItem(at: staging)
        try runDitto(["-x", "-k", source.path, staging.path])
        try flattenSingleRootDirectory(at: staging)

        guard !(try FileManager.default.contentsOfDirectory(atPath: staging.path)).isEmpty else {
            try? FileManager.default.removeItem(at: staging)
            throw SaveManagerError.invalidArchive
        }

        let backup = parent.appendingPathComponent("\(directory.lastPathComponent).backup-\(UUID().uuidString)")
        let fileManager = FileManager.default
        let hadExisting = fileManager.fileExists(atPath: directory.path)
        if hadExisting {
            try fileManager.moveItem(at: directory, to: backup)
        }
        do {
            try fileManager.moveItem(at: staging, to: directory)
            try? fileManager.removeItem(at: backup)
        } catch {
            if hadExisting, fileManager.fileExists(atPath: backup.path) {
                try? fileManager.moveItem(at: backup, to: directory)
            }
            try? fileManager.removeItem(at: staging)
            throw error
        }
    }

    static func deleteAll(game: Game) throws {
        let directory = saveDirectory(for: game)
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else { return }
        for item in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            try fileManager.removeItem(at: item)
        }
    }

    private static func flattenSingleRootDirectory(at directory: URL) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        guard contents.count == 1,
              let only = contents.first,
              (try? only.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return }

        for child in try fileManager.contentsOfDirectory(at: only, includingPropertiesForKeys: nil) {
            try fileManager.moveItem(at: child, to: directory.appendingPathComponent(child.lastPathComponent))
        }
        try fileManager.removeItem(at: only)
    }

    private static func runDitto(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = arguments
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw SaveManagerError.commandFailed(message.isEmpty ? "压缩/解压失败" : message)
        }
    }
}
