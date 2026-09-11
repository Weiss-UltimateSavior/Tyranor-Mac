import AppKit
import Foundation

enum CoverImageCache {
    private static let maxCoverBytes = 20 * 1024 * 1024
    private static let imageCache = NSCache<NSString, NSImage>()

    static var coversDirectory: URL {
        GameStore.directoryURL.appendingPathComponent("covers", isDirectory: true)
    }

    @discardableResult
    static func ensureCoversDirectory() -> URL {
        let directory = coversDirectory
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    static func download(url imageURL: String, prefix: String, source: CoverSource) async -> String? {
        guard let url = URL(string: imageURL), !imageURL.isEmpty else { return nil }
        let directory = ensureCoversDirectory()
        let safePrefix = prefix.replacingOccurrences(
            of: "[^A-Za-z0-9_.-]",
            with: "_",
            options: .regularExpression
        )
        let target = directory.appendingPathComponent("\(safePrefix)_\(CoverSupport.stableKey(imageURL)).jpg")
        if FileManager.default.fileExists(atPath: target.path) {
            return target.path
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(
            "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        if let referer = referer(for: source) {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }
        if let cookie = cookie(for: source) {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            guard !data.isEmpty, data.count <= maxCoverBytes else { return nil }
            let temporary = directory.appendingPathComponent("\(target.lastPathComponent).tmp")
            try? FileManager.default.removeItem(at: temporary)
            try data.write(to: temporary)
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.moveItem(at: temporary, to: target)
            imageCache.removeObject(forKey: target.path as NSString)
            return target.path
        } catch {
            return nil
        }
    }

    static func saveCustomCover(from sourceURL: URL, gameID: UUID) -> String? {
        let directory = ensureCoversDirectory()
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension.lowercased()
        let target = directory.appendingPathComponent("custom_\(CoverSupport.stableKey(gameID.uuidString)).\(ext)")
        do {
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.copyItem(at: sourceURL, to: target)
            imageCache.removeObject(forKey: target.path as NSString)
            return target.path
        } catch {
            return nil
        }
    }

    static func loadImage(path: String?) -> NSImage? {
        guard let path, !path.isEmpty else { return nil }
        if let cached = imageCache.object(forKey: path as NSString) {
            return cached
        }
        guard FileManager.default.fileExists(atPath: path),
              let image = NSImage(contentsOfFile: path) else { return nil }
        imageCache.setObject(image, forKey: path as NSString)
        return image
    }

    private static func referer(for source: CoverSource) -> String? {
        switch source {
        case .vndb:
            return "https://vndb.org/"
        case .bangumi:
            return "https://bgm.tv/"
        case .steam:
            return "https://store.steampowered.com/"
        case .local, .custom:
            return nil
        }
    }

    private static func cookie(for source: CoverSource) -> String? {
        switch source {
        case .vndb:
            return "vndb_img=1; vndb_samesite=1"
        case .bangumi, .steam, .local, .custom:
            return nil
        }
    }
}
