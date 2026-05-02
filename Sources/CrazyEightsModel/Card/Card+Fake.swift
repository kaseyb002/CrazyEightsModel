import Foundation

extension Card {
    public static func fake(
        id: CardID = .random(in: 1000 ... 9999),
        rank: Rank = Rank.allCases.randomElement()!,
        suit: Suit = Suit.allCases.randomElement()!
    ) -> Card {
        .init(
            id: id,
            rank: rank,
            suit: suit
        )
    }
}
