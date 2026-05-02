import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card]? = nil,
        players: [Player] = [
            .fake(),
            .fake(),
        ]
    ) throws -> Round {
        if let cookedDeck {
            return try self.init(
                id: id,
                started: started,
                cookedDeck: cookedDeck,
                players: players
            )
        } else {
            return try self.init(
                id: id,
                started: started,
                players: players
            )
        }
    }
}
