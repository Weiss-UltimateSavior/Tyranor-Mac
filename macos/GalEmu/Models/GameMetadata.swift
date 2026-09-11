import Foundation

struct GameMetadata: Hashable, Codable {
    var developer: String
    var releaseYear: Int
    var summary: String
    var tags: [String]
    var directoryPath: String
    var originalTitle: String?
    var releaseDate: String?
}
