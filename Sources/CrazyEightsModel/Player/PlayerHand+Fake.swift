import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        cards: [CardID] = []
    ) -> PlayerHand {
        .init(
            player: player,
            cards: cards
        )
    }
}
