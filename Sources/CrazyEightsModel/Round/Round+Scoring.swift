import Foundation

extension Round {
    /// Calculates the total value of cards remaining in a player's hand.
    public func handValue(for playerID: PlayerID) -> Int {
        guard let playerHand: PlayerHand = playerHands.first(where: { $0.player.id == playerID }) else {
            return 0
        }
        let cards: [Card] = playerHand.cards.compactMap { cardsMap[$0] }
        return cards.totalScoringValue
    }

    /// Returns the scores from a completed round, or nil if the round is still in progress.
    public var finalScores: [PlayerID: Int]? {
        switch state {
        case .roundComplete(_, let scores):
            scores

        case .waitingForPlayer:
            nil
        }
    }
}
