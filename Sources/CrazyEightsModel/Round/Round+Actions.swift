import Foundation

extension Round {
    /// Play a card from the current player's hand onto the discard pile.
    /// If the card is an eight, `declaredSuit` must be provided.
    /// For non-eights, `declaredSuit` is ignored.
    public mutating func playCard(
        cardID: CardID,
        declaredSuit: Card.Suit? = nil
    ) throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw CrazyEightsError.roundIsComplete
        }
        guard let handIndex: Int = playerHands.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw CrazyEightsError.playerNotFound
        }
        guard playerHands[handIndex].cards.contains(cardID) else {
            throw CrazyEightsError.cardNotInPlayersHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw CrazyEightsError.cardNotInPlayersHand
        }

        if card.isEight {
            guard let declaredSuit else {
                throw CrazyEightsError.mustSpecifySuitForEight
            }
            playerHands[handIndex].cards.removeAll(where: { $0 == cardID })
            discardPile.append(cardID)
            self.declaredSuit = declaredSuit

            log.addAction(.init(
                playerID: currentPlayerID,
                decision: .playCard(cardId: cardID, declaredSuit: declaredSuit)
            ))
        } else {
            guard canPlay(card: card) else {
                throw CrazyEightsError.cardNotPlayable
            }
            playerHands[handIndex].cards.removeAll(where: { $0 == cardID })
            discardPile.append(cardID)
            self.declaredSuit = nil

            log.addAction(.init(
                playerID: currentPlayerID,
                decision: .playCard(cardId: cardID, declaredSuit: nil)
            ))
        }

        if playerHands[handIndex].cards.isEmpty {
            endRound(winnerID: currentPlayerID)
            return
        }

        advanceToNextPlayer(currentHandIndex: handIndex)
    }

    /// Draw a card from the stock. A player may draw even if they have a playable card.
    /// If the stock is empty, the discard pile is reshuffled into the stock (keeping the top card).
    /// If both are empty after reshuffling, the player must pass.
    public mutating func drawCard() throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw CrazyEightsError.roundIsComplete
        }
        guard let handIndex: Int = playerHands.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw CrazyEightsError.playerNotFound
        }

        if stock.isEmpty {
            reshuffleDiscardIntoStock()
        }

        guard stock.isEmpty == false else {
            throw CrazyEightsError.stockAndDiscardPileEmpty
        }

        let drawnCardID: CardID = stock.removeLast()
        playerHands[handIndex].cards.append(drawnCardID)

        log.addAction(.init(
            playerID: currentPlayerID,
            decision: .draw(cardId: drawnCardID)
        ))
    }

    /// Pass the turn. Only allowed when the stock is exhausted and the player has no playable cards.
    public mutating func pass() throws {
        guard case .waitingForPlayer(let currentPlayerID) = state else {
            throw CrazyEightsError.roundIsComplete
        }
        guard let handIndex: Int = playerHands.firstIndex(where: { $0.player.id == currentPlayerID }) else {
            throw CrazyEightsError.playerNotFound
        }

        log.addAction(.init(
            playerID: currentPlayerID,
            decision: .pass
        ))

        advanceToNextPlayer(currentHandIndex: handIndex)
    }

    // MARK: - Private Helpers

    private func canPlay(card: Card) -> Bool {
        guard let topCardID: CardID = discardPile.last,
              let topCard: Card = cardsMap[topCardID]
        else {
            return true
        }

        if card.isEight {
            return true
        }

        if let activeSuit: Card.Suit = declaredSuit {
            return card.suit == activeSuit
        }

        return card.suit == topCard.suit || card.rank == topCard.rank
    }

    private mutating func reshuffleDiscardIntoStock() {
        guard discardPile.count > 1 else { return }
        let topCard: CardID = discardPile.removeLast()
        stock = discardPile.shuffled()
        discardPile = [topCard]
    }

    private mutating func advanceToNextPlayer(currentHandIndex: Int) {
        let nextIndex: Int = (currentHandIndex + 1) % playerHands.count
        state = .waitingForPlayer(id: playerHands[nextIndex].player.id)
    }

    private mutating func endRound(winnerID: PlayerID) {
        var scores: [PlayerID: Int] = [:]
        for playerHand in playerHands {
            let handCards: [Card] = playerHand.cards.compactMap { cardsMap[$0] }
            scores[playerHand.player.id] = handCards.totalScoringValue
        }

        let winnerScore: Int = scores.filter { $0.key != winnerID }.values.reduce(0, +)
        scores[winnerID] = winnerScore

        state = .roundComplete(winnerID: winnerID, scores: scores)
        ended = .now
    }
}
