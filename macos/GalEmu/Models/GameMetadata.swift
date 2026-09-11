import Foundation

struct GameMetadata: Hashable {
    var developer: String
    var releaseYear: Int
    var summary: String
    var tags: [String]
    var directoryPath: String
}
