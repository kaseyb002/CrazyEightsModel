import Foundation

extension Player {
    public static func fake(
        id: PlayerID = UUID().uuidString,
        name: String = "Fake Player",
        imageURL: URL? = nil,
        score: Int = 0
    ) -> Player {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            score: score
        )
    }
}
