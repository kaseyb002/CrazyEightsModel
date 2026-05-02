import Foundation

extension Round {
    public var currentPlayerHandIndex: Int? {
        switch state {
        case .waitingForPlayer(let playerID):
            return playerHands.firstIndex(where: { $0.player.id == playerID })

        case .roundComplete:
            return nil
        }
    }

    public var currentPlayerHand: PlayerHand? {
        guard let currentPlayerHandIndex else {
            return nil
        }
        return playerHands[currentPlayerHandIndex]
    }

    public var currentPlayerID: PlayerID? {
        switch state {
        case .waitingForPlayer(let id):
            id

        case .roundComplete:
            nil
        }
    }

    public var topDiscardCard: Card? {
        guard let topID: CardID = discardPile.last else {
            return nil
        }
        return cardsMap[topID]
    }

    /// The suit that the next player must match.
    /// If an eight was played and a suit was declared, returns the declared suit.
    /// Otherwise returns the suit of the top discard card.
    public var activeSuit: Card.Suit? {
        if let declaredSuit {
            return declaredSuit
        }
        return topDiscardCard?.suit
    }

    /// The rank that the next player can match (ignored if a suit was declared via eight).
    public var activeRank: Card.Rank? {
        if declaredSuit != nil {
            return nil
        }
        return topDiscardCard?.rank
    }

    public func isPlayersTurn(playerID: PlayerID) -> Bool {
        switch state {
        case .waitingForPlayer(let id):
            playerID == id

        case .roundComplete:
            false
        }
    }

    public func player(byID id: PlayerID) -> Player? {
        playerHands.first(where: { $0.player.id == id })?.player
    }

    /// Returns the playable cards from the current player's hand.
    public func playableCards(for playerID: PlayerID) -> [Card] {
        guard let playerHand: PlayerHand = playerHands.first(where: { $0.player.id == playerID }) else {
            return []
        }
        return playerHand.cards.compactMap { cardID -> Card? in
            guard let card: Card = cardsMap[cardID] else { return nil }
            if card.isEight { return card }
            if let activeSuit, let activeRank {
                if card.suit == activeSuit || card.rank == activeRank {
                    return card
                }
                return nil
            }
            if let activeSuit {
                return card.suit == activeSuit ? card : nil
            }
            return card
        }
    }

    public var logValue: String {
        """
        State: \(state.logValue)
        Stock remaining: \(stock.count)
        Discard pile count: \(discardPile.count)
        Top discard: \(topDiscardCard?.debugDescription ?? "None")
        Active suit: \(activeSuit?.displayableName ?? "None")
        Current player: \(currentPlayerHand?.player.name ?? "None")
        """
    }
}

extension Round.State {
    public var isComplete: Bool {
        switch self {
        case .roundComplete:
            true

        case .waitingForPlayer:
            false
        }
    }
}
