import Foundation

public enum AIDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

public struct AIEngine: Sendable {
    private let difficulty: AIDifficulty

    public init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }

    /// Returns the action the AI wants to take. The caller is responsible for
    /// mutating the round.
    public func chooseAction(for round: Round, playerID: PlayerID) -> AIAction {
        guard let playerHand: PlayerHand = round.playerHands.first(where: { $0.player.id == playerID }) else {
            return .draw
        }

        let playable: [Card] = round.playableCards(for: playerID)

        if playable.isEmpty {
            if round.stock.isEmpty {
                return .pass
            }
            return .draw
        }

        switch difficulty {
        case .easy:
            return chooseEasy(playable: playable, playerHand: playerHand, round: round)
        case .medium:
            return chooseMedium(playable: playable, playerHand: playerHand, round: round)
        case .hard:
            return chooseHard(playable: playable, playerHand: playerHand, round: round)
        }
    }

    // MARK: - Easy

    private func chooseEasy(playable: [Card], playerHand: PlayerHand, round: Round) -> AIAction {
        let card: Card = playable.randomElement()!
        if card.isEight {
            let suit: Card.Suit = Card.Suit.allCases.randomElement()!
            return .playCard(cardID: card.id, declaredSuit: suit)
        }
        return .playCard(cardID: card.id, declaredSuit: nil)
    }

    // MARK: - Medium

    private func chooseMedium(playable: [Card], playerHand: PlayerHand, round: Round) -> AIAction {
        let handCards: [Card] = playerHand.cards.compactMap { round.cardsMap[$0] }

        let nonEights: [Card] = playable.filter { $0.isEight == false }
        if nonEights.isEmpty == false {
            let best: Card = pickBestNonEight(from: nonEights, hand: handCards)
            return .playCard(cardID: best.id, declaredSuit: nil)
        }

        let eight: Card = playable.first(where: { $0.isEight })!
        let bestSuit: Card.Suit = mostFrequentSuit(in: handCards, excluding: eight.id)
        return .playCard(cardID: eight.id, declaredSuit: bestSuit)
    }

    // MARK: - Hard

    private func chooseHard(playable: [Card], playerHand: PlayerHand, round: Round) -> AIAction {
        let handCards: [Card] = playerHand.cards.compactMap { round.cardsMap[$0] }

        if shouldDrawForBetterPlay(playable: playable, hand: handCards, round: round) {
            if round.stock.isEmpty == false {
                return .draw
            }
        }

        let nonEights: [Card] = playable.filter { $0.isEight == false }
        if nonEights.isEmpty == false {
            let best: Card = pickBestNonEightHard(from: nonEights, hand: handCards, round: round)
            return .playCard(cardID: best.id, declaredSuit: nil)
        }

        let eight: Card = playable.first(where: { $0.isEight })!
        let bestSuit: Card.Suit = mostFrequentSuit(in: handCards, excluding: eight.id)
        return .playCard(cardID: eight.id, declaredSuit: bestSuit)
    }

    // MARK: - Helpers

    private func pickBestNonEight(from cards: [Card], hand: [Card]) -> Card {
        let suitCounts: [Card.Suit: Int] = suitFrequency(in: hand)

        return cards.max(by: { a, b in
            let aScore: Int = (suitCounts[a.suit] ?? 0) + a.scoringValue
            let bScore: Int = (suitCounts[b.suit] ?? 0) + b.scoringValue
            return aScore < bScore
        })!
    }

    private func pickBestNonEightHard(from cards: [Card], hand: [Card], round: Round) -> Card {
        let suitCounts: [Card.Suit: Int] = suitFrequency(in: hand)

        return cards.max(by: { a, b in
            scoreCard(a, suitCounts: suitCounts, hand: hand, round: round)
                < scoreCard(b, suitCounts: suitCounts, hand: hand, round: round)
        })!
    }

    private func scoreCard(
        _ card: Card,
        suitCounts: [Card.Suit: Int],
        hand: [Card],
        round: Round
    ) -> Int {
        var score: Int = card.scoringValue

        score += (suitCounts[card.suit] ?? 0) * 3

        let rankCount: Int = hand.filter { $0.rank == card.rank }.count
        score += rankCount * 2

        let nextPlayerIndex: Int = nextPlayerHandIndex(in: round)
        let nextPlayerCardCount: Int = round.playerHands[nextPlayerIndex].cards.count
        if nextPlayerCardCount <= 2 {
            score += card.scoringValue
        }

        return score
    }

    private func shouldDrawForBetterPlay(playable: [Card], hand: [Card], round: Round) -> Bool {
        let nonEights: [Card] = playable.filter { $0.isEight == false }
        if nonEights.isEmpty && playable.count == 1 && hand.count > 2 {
            return true
        }
        return false
    }

    private func mostFrequentSuit(in cards: [Card], excluding cardID: CardID) -> Card.Suit {
        let filtered: [Card] = cards.filter { $0.id != cardID && $0.isEight == false }
        let counts: [Card.Suit: Int] = suitFrequency(in: filtered)

        return counts.max(by: { $0.value < $1.value })?.key
            ?? Card.Suit.allCases.randomElement()!
    }

    private func suitFrequency(in cards: [Card]) -> [Card.Suit: Int] {
        var counts: [Card.Suit: Int] = [:]
        for card in cards where card.isEight == false {
            counts[card.suit, default: 0] += 1
        }
        return counts
    }

    private func nextPlayerHandIndex(in round: Round) -> Int {
        guard let currentIndex: Int = round.currentPlayerHandIndex else {
            return 0
        }
        return (currentIndex + 1) % round.playerHands.count
    }
}

public enum AIAction: Equatable, Sendable {
    case playCard(cardID: CardID, declaredSuit: Card.Suit?)
    case draw
    case pass
}

extension Round {
    public mutating func makeAIMove(difficulty: AIDifficulty, playerID: PlayerID) throws {
        let ai: AIEngine = .init(difficulty: difficulty)
        let action: AIAction = ai.chooseAction(for: self, playerID: playerID)

        switch action {
        case .playCard(let cardID, let declaredSuit):
            try playCard(cardID: cardID, declaredSuit: declaredSuit)

        case .draw:
            try drawCard()

        case .pass:
            try pass()
        }
    }
}
