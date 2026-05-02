import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw CrazyEightsError.notEnoughPlayers
        }
        guard players.count <= 8 else {
            throw CrazyEightsError.tooManyPlayers
        }
        var deck: Deck = .standard()
        deck.shuffle()
        try self.init(
            id: id,
            started: started,
            cookedDeck: deck.cards,
            players: players
        )
    }

    /// Internal initializer accepting a pre-ordered deck for deterministic tests.
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        cookedDeck: [Card],
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw CrazyEightsError.notEnoughPlayers
        }
        guard players.count <= 8 else {
            throw CrazyEightsError.tooManyPlayers
        }
        self.id = id
        self.started = started

        var remaining: [Card] = cookedDeck
        self.cardsMap = Dictionary(uniqueKeysWithValues: remaining.map { ($0.id, $0) })

        var hands: [PlayerHand] = []
        for player in players {
            let dealt: [Card] = Array(remaining.suffix(Self.cardsPerPlayer))
            remaining.removeLast(Self.cardsPerPlayer)
            hands.append(PlayerHand(player: player, cards: dealt.map(\.id)))
        }
        self.playerHands = hands

        var starter: Card = remaining.removeLast()
        while starter.isEight {
            remaining.insert(starter, at: remaining.count / 2)
            starter = remaining.removeLast()
        }

        self.discardPile = [starter.id]
        self.stock = remaining.map(\.id)
        self.declaredSuit = nil
        self.state = .waitingForPlayer(id: players.first!.id)
    }
}
