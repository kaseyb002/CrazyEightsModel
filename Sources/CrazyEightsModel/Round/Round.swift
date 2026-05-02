import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var stock: [CardID]
    public internal(set) var discardPile: [CardID]
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var declaredSuit: Card.Suit?

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public static let cardsPerPlayer: Int = 5

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayer(id: PlayerID)
        case roundComplete(winnerID: PlayerID, scores: [PlayerID: Int])

        public var logValue: String {
            switch self {
            case .waitingForPlayer(let playerID):
                "Waiting for player \(playerID)"

            case .roundComplete(let winnerID, let scores):
                "Round complete. Winner: \(winnerID). Scores: \(scores)"
            }
        }
    }
}
