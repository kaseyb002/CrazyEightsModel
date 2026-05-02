import Foundation

public typealias CardID = Int

public struct Card: Equatable, Hashable, Identifiable, Codable, Sendable {
    public let id: CardID
    public let rank: Rank
    public let suit: Suit

    public var debugDescription: String {
        "\(rank.displayValue)\(suit.emoji)"
    }

    public init(
        id: CardID,
        rank: Rank,
        suit: Suit
    ) {
        self.id = id
        self.rank = rank
        self.suit = suit
    }

    public var isEight: Bool {
        rank == .eight
    }

    public var scoringValue: Int {
        switch rank {
        case .eight:
            50
        case .king, .queen, .jack, .ten:
            10
        case .ace:
            1
        case .two:
            2
        case .three:
            3
        case .four:
            4
        case .five:
            5
        case .six:
            6
        case .seven:
            7
        case .nine:
            9
        }
    }
}
