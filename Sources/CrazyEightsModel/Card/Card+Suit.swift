import Foundation

extension Card {
    public enum Suit: String, Hashable, CaseIterable, Codable, Sendable {
        case hearts
        case clubs
        case diamonds
        case spades

        public var displayableName: String {
            switch self {
            case .hearts: "Hearts"
            case .clubs: "Clubs"
            case .diamonds: "Diamonds"
            case .spades: "Spades"
            }
        }

        public var emoji: String {
            switch self {
            case .hearts: "♥️"
            case .clubs: "♣️"
            case .diamonds: "♦️"
            case .spades: "♠️"
            }
        }
    }
}
