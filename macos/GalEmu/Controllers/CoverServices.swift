import Foundation

struct CoverCandidate {
    let url: String
    let source: CoverSource
}

enum CoverServices {
    static func candidates(query: String, source: CoverSource) async -> [CoverCandidate] {
        switch source {
        case .vndb:
            return await vndbCandidates(query: query)
        case .bangumi:
            return await bangumiCandidates(query: query)
        case .steam:
            return await steamCandidates(query: query)
        case .local, .custom:
            return []
        }
    }

    private static func vndbCandidates(query: String) async -> [CoverCandidate] {
        await VNDBThrottle.shared.wait()
        let body: [String: Any] = [
            "filters": ["search", "=", query],
            "fields": "title,alttitle,titles.lang,titles.title,titles.main,image.url,image.thumbnail",
            "sort": "searchrank",
            "results": 1,
        ]
        guard let json = await CoverHTTP.json(
            url: "https://api.vndb.org/kana/vn",
            method: "POST",
            body: body
        ) else { return [] }
        guard let results = json["results"] as? [[String: Any]],
              let first = results.first,
              let image = first["image"] as? [String: Any] else { return [] }

        let thumbnail = image["thumbnail"] as? String ?? ""
        let full = image["url"] as? String ?? ""
        let url = thumbnail.isEmpty ? full : thumbnail
        guard !url.isEmpty else { return [] }
        return [CoverCandidate(url: url, source: .vndb)]
    }

    private static func bangumiCandidates(query: String) async -> [CoverCandidate] {
        let body: [String: Any] = [
            "keyword": query,
            "sort": "rank",
            "filter": ["type": [4], "nsfw": true],
        ]
        guard let json = await CoverHTTP.json(
            url: "https://api.bgm.tv/v0/search/subjects?limit=3&offset=0",
            method: "POST",
            body: body,
            headers: ["User-Agent": "TyranorMac/0.1 (https://github.com/Weiss-UltimateSavior)"]
        ) else { return [] }
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        return data.compactMap { item in
            guard let images = item["images"] as? [String: Any] else { return nil }
            let large = images["large"] as? String ?? ""
            let common = images["common"] as? String ?? ""
            let url = large.isEmpty ? common : large
            guard !url.isEmpty else { return nil }
            return CoverCandidate(url: url, source: .bangumi)
        }
    }

    private static func steamCandidates(query: String) async -> [CoverCandidate] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let search = await CoverHTTP.json(
                  url: "https://store.steampowered.com/api/storesearch/?term=\(encoded)&l=schinese&cc=CN"
              ),
              let items = search["items"] as? [[String: Any]],
              let first = items.first,
              let appID = first["id"] as? Int else { return [] }

        var candidates = [
            CoverCandidate(
                url: "https://cdn.akamai.steamstatic.com/steam/apps/\(appID)/library_600x900.jpg",
                source: .steam
            )
        ]

        if let details = await CoverHTTP.json(
            url: "https://store.steampowered.com/api/appdetails?appids=\(appID)&l=schinese&cc=CN"
        ),
            let entry = details["\(appID)"] as? [String: Any],
            let data = entry["data"] as? [String: Any],
            let header = data["header_image"] as? String,
            !header.isEmpty {
            candidates.append(CoverCandidate(url: header, source: .steam))
        }
        return candidates
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
