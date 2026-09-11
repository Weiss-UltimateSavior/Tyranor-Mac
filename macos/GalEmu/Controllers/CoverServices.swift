import Foundation

struct CoverMetadata {
    var originalTitle: String?
    var developer: String?
    var releaseDate: String?
    var summary: String?
    var tags: [String] = []
}

struct CoverCandidate {
    let url: String
    let previewURL: String?
    let source: CoverSource
    let title: String
    let subtitle: String
    let detail: String
    let metadata: CoverMetadata?
}

enum CoverServices {
    static func candidates(query: String, source: CoverSource, limit: Int = 8) async -> [CoverCandidate] {
        switch source {
        case .vndb:
            return await vndbCandidates(query: query, limit: limit)
        case .bangumi:
            return await bangumiCandidates(query: query, limit: limit)
        case .steam:
            return await steamCandidates(query: query, limit: limit)
        case .local, .custom:
            return []
        }
    }

    private static func vndbCandidates(query: String, limit: Int) async -> [CoverCandidate] {
        await VNDBThrottle.shared.wait()
        let body: [String: Any] = [
            "filters": ["search", "=", query],
            "fields": "id,title,alttitle,titles.lang,titles.title,titles.main,released,description,"
                + "developers.name,developers.original,image.url,image.thumbnail,"
                + "tags.name,tags.rating,tags.spoiler,tags.category",
            "sort": "searchrank",
            "results": max(1, min(limit, 10)),
        ]
        guard let json = await CoverHTTP.json(
            url: "https://api.vndb.org/kana/vn",
            method: "POST",
            body: body
        ) else { return [] }
        guard let results = json["results"] as? [[String: Any]] else { return [] }

        return results.compactMap { item in
            guard let image = item["image"] as? [String: Any] else { return nil }
            let thumbnail = image["thumbnail"] as? String ?? ""
            let full = image["url"] as? String ?? ""
            let url = full.isEmpty ? thumbnail : full
            guard !url.isEmpty else { return nil }

            var metadata = CoverMetadata()
            metadata.originalTitle = mainTitle(of: item)
            metadata.releaseDate = (item["released"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            metadata.summary = cleanDescription(item["description"] as? String)
            metadata.developer = developers(of: item)
            metadata.tags = vndbTags(of: item)

            let displayTitle = chineseTitle(of: item) ?? metadata.originalTitle ?? (item["title"] as? String ?? "")
            var details: [String] = ["VNDB"]
            if let id = item["id"] as? String, !id.isEmpty { details.append(id) }
            if let released = metadata.releaseDate { details.append(released) }
            if let developer = metadata.developer { details.append(developer) }

            return CoverCandidate(
                url: url,
                previewURL: thumbnail.isEmpty ? url : thumbnail,
                source: .vndb,
                title: displayTitle,
                subtitle: metadata.originalTitle ?? "",
                detail: details.joined(separator: " · "),
                metadata: metadata
            )
        }
    }

    private static func bangumiCandidates(query: String, limit: Int) async -> [CoverCandidate] {
        let body: [String: Any] = [
            "keyword": query,
            "sort": "rank",
            "filter": ["type": [4], "nsfw": true],
        ]
        guard let json = await CoverHTTP.json(
            url: "https://api.bgm.tv/v0/search/subjects?limit=\(max(1, min(limit, 10)))&offset=0",
            method: "POST",
            body: body,
            headers: ["User-Agent": "TyranorMac/0.1 (https://github.com/Weiss-UltimateSavior)"]
        ) else { return [] }
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        return data.compactMap { item in
            guard let images = item["images"] as? [String: Any] else { return nil }
            let large = images["large"] as? String ?? ""
            let common = images["common"] as? String ?? ""
            let medium = images["medium"] as? String ?? ""
            let url = large.isEmpty ? common : large
            let preview = common.isEmpty ? (medium.isEmpty ? url : medium) : common
            guard !url.isEmpty else { return nil }

            var metadata = CoverMetadata()
            let name = item["name"] as? String ?? ""
            let nameCN = item["name_cn"] as? String ?? ""
            if !name.isEmpty { metadata.originalTitle = name }
            if let date = item["date"] as? String, !date.isEmpty { metadata.releaseDate = date }
            metadata.summary = (item["summary"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            metadata.tags = bangumiTags(of: item)

            var details: [String] = ["Bangumi"]
            if let id = item["id"] as? Int { details.append("\(id)") }
            if let date = metadata.releaseDate { details.append(date) }

            return CoverCandidate(
                url: url,
                previewURL: preview,
                source: .bangumi,
                title: nameCN.isEmpty ? name : nameCN,
                subtitle: name,
                detail: details.joined(separator: " · "),
                metadata: metadata
            )
        }
    }

    private static func steamCandidates(query: String, limit: Int) async -> [CoverCandidate] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let search = await CoverHTTP.json(
                  url: "https://store.steampowered.com/api/storesearch/?term=\(encoded)&l=schinese&cc=CN"
              ),
              let items = search["items"] as? [[String: Any]] else { return [] }

        var candidates: [CoverCandidate] = []
        for item in items.prefix(max(1, min(limit, 10))) {
            guard let appID = item["id"] as? Int, appID > 0 else { continue }
            let name = item["name"] as? String ?? ""

            var metadata = CoverMetadata()
            metadata.originalTitle = name.isEmpty ? nil : name
            var primaryURL = "https://cdn.akamai.steamstatic.com/steam/apps/\(appID)/library_600x900.jpg"

            if let details = await CoverHTTP.json(
                url: "https://store.steampowered.com/api/appdetails?appids=\(appID)&l=schinese&cc=CN"
            ),
                let entry = details["\(appID)"] as? [String: Any],
                let data = entry["data"] as? [String: Any] {
                metadata.summary = (data["short_description"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                metadata.developer = (data["developers"] as? [String])?.first
                if let release = data["release_date"] as? [String: Any],
                   let date = release["date"] as? String,
                   !date.isEmpty {
                    metadata.releaseDate = date
                }
                metadata.tags = (data["genres"] as? [[String: Any]] ?? [])
                    .compactMap { $0["description"] as? String }
                if let header = data["header_image"] as? String, !header.isEmpty {
                    primaryURL = header
                }
            }

            candidates.append(
                CoverCandidate(
                    url: primaryURL,
                    previewURL: item["tiny_image"] as? String,
                    source: .steam,
                    title: name,
                    subtitle: "",
                    detail: "Steam · \(appID)",
                    metadata: metadata
                )
            )
        }
        return candidates
    }

    private static func chineseTitle(of item: [String: Any]) -> String? {
        guard let titles = item["titles"] as? [[String: Any]] else { return nil }
        for lang in ["zh-Hans", "zh-Hant", "zh"] {
            if let match = titles.first(where: { ($0["lang"] as? String) == lang }),
               let title = match["title"] as? String,
               !title.isEmpty {
                return title
            }
        }
        return nil
    }

    private static func mainTitle(of item: [String: Any]) -> String? {
        if let alt = item["alttitle"] as? String, !alt.isEmpty {
            return alt
        }
        if let titles = item["titles"] as? [[String: Any]] {
            if let main = titles.first(where: { ($0["main"] as? Bool) == true }),
               let title = main["title"] as? String,
               !title.isEmpty {
                return title
            }
        }
        return (item["title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func developers(of item: [String: Any]) -> String? {
        guard let devs = item["developers"] as? [[String: Any]] else { return nil }
        for dev in devs {
            let original = dev["original"] as? String ?? ""
            let name = dev["name"] as? String ?? ""
            let value = original.isEmpty ? name : original
            if !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func vndbTags(of item: [String: Any]) -> [String] {
        let raw = item["tags"] as? [[String: Any]] ?? []
        return raw.compactMap { tag -> (String, Int)? in
            guard (tag["spoiler"] as? Int ?? 0) == 0,
                  (tag["category"] as? String) == "cont",
                  let name = tag["name"] as? String,
                  !name.isEmpty else { return nil }
            return (name, tag["rating"] as? Int ?? 0)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(6)
        .map(\.0)
    }

    private static func bangumiTags(of item: [String: Any]) -> [String] {
        let raw = item["tags"] as? [[String: Any]] ?? []
        return raw.compactMap { tag -> (String, Int)? in
            guard let name = tag["name"] as? String, !name.isEmpty else { return nil }
            return (name, tag["count"] as? Int ?? 0)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(6)
        .map(\.0)
    }

    private static func cleanDescription(_ text: String?) -> String? {
        guard var value = text, !value.isEmpty else { return nil }
        value = value.replacingOccurrences(of: #"\[/?[^\]]+\]"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

enum CoverHTTP {
    static func json(
        url: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String] = [:]
    ) async -> [String: Any]? {
        guard let target = URL(string: url) else { return nil }
        var request = URLRequest(url: target)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("TyranorMac/0.1", forHTTPHeaderField: "User-Agent")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            return nil
        }
    }
}

actor VNDBThrottle {
    static let shared = VNDBThrottle()

    private var lastRequest = Date.distantPast
    private let minInterval: TimeInterval = 1.1

    func wait() async {
        let elapsed = Date().timeIntervalSince(lastRequest)
        if elapsed < minInterval {
            try? await Task.sleep(nanoseconds: UInt64((minInterval - elapsed) * 1_000_000_000))
        }
        lastRequest = Date()
    }
}
