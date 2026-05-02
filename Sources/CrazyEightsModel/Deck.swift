import Foundation

public struct Deck: Equatable, Codable, Sendable {
    public var cards: [Card]

    public static func standard() -> Deck {
        var cards: [Card] = []
        var nextID: CardID = 0
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                let card: Card = .init(
                    id: nextID,
                    rank: rank,
                    suit: suit
                )
                cards.append(card)
                nextID += 1
            }
        }
        return Deck(cards: cards)
    }

    public init(cards: [Card]) {
        self.cards = cards
    }

    public mutating func shuffle() {
        cards.shuffle()
    }
}
