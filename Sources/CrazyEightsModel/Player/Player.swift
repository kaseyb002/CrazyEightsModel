import Foundation

public typealias PlayerID = String

public struct Player: Equatable, Codable, Sendable {
    public let id: PlayerID
    public var name: String
    public var imageURL: URL?
    public var score: Int

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageURL = "imageUrl"
        case score
    }

    public init(
        id: PlayerID,
        name: String,
        imageURL: URL?,
        score: Int
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.score = score
    }
}
