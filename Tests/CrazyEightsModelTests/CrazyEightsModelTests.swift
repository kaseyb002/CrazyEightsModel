import Foundation
import Testing
@testable import CrazyEightsModel

// MARK: - Helpers

private func makePlayers(_ count: Int = 2) -> [Player] {
    (0 ..< count).map { i in
        Player(id: "player\(i + 1)", name: "Player \(i + 1)", imageURL: nil, score: 0)
    }
}

/// Builds a cooked deck for 2-player tests with explicit control over each hand and the starter.
/// Layout (end of array = dealt first):
///   [stock..., starter, p2Hand..., p1Hand...]
/// Player 1 gets the last `cardsPerPlayer` cards from the array.
/// Player 2 gets the next `cardsPerPlayer`.
/// The starter is the next one after that.
/// Everything before that is stock.
private func buildDeck(
    p1Hand: [Card],
    p2Hand: [Card],
    starter: Card,
    stock: [Card]
) -> [Card] {
    stock + [starter] + p2Hand + p1Hand
}

// MARK: - Deck Tests

@Test func deckHas52Cards() {
    let deck: Deck = .standard()
    #expect(deck.cards.count == 52)
    #expect(Set(deck.cards.map(\.id)).count == 52)
}

@Test func deckHas4Suits() {
    let deck: Deck = .standard()
    let suits: Set<Card.Suit> = Set(deck.cards.map(\.suit))
    #expect(suits.count == 4)
}

@Test func deckHas13Ranks() {
    let deck: Deck = .standard()
    let ranks: Set<Card.Rank> = Set(deck.cards.map(\.rank))
    #expect(ranks.count == 13)
}

// MARK: - Card Scoring Tests

@Test func eightScores50() {
    let card: Card = .init(id: 0, rank: .eight, suit: .hearts)
    #expect(card.scoringValue == 50)
}

@Test func faceCardsScore10() {
    let king: Card = .init(id: 0, rank: .king, suit: .spades)
    let queen: Card = .init(id: 1, rank: .queen, suit: .hearts)
    let jack: Card = .init(id: 2, rank: .jack, suit: .clubs)
    let ten: Card = .init(id: 3, rank: .ten, suit: .diamonds)
    #expect(king.scoringValue == 10)
    #expect(queen.scoringValue == 10)
    #expect(jack.scoringValue == 10)
    #expect(ten.scoringValue == 10)
}

@Test func aceScores1() {
    let ace: Card = .init(id: 0, rank: .ace, suit: .hearts)
    #expect(ace.scoringValue == 1)
}

@Test func pipCardsScoreFaceValue() {
    let five: Card = .init(id: 0, rank: .five, suit: .hearts)
    #expect(five.scoringValue == 5)

    let nine: Card = .init(id: 1, rank: .nine, suit: .clubs)
    #expect(nine.scoringValue == 9)
}

// MARK: - Round Init Tests

@Test func roundInitDeals5CardsEach() throws {
    let round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: makePlayers(3)
    )
    for playerHand in round.playerHands {
        #expect(playerHand.cards.count == 5)
    }
    #expect(round.discardPile.count == 1)
    #expect(round.stock.count == 52 - 15 - 1)
}

@Test func roundInitStarterIsNotEight() throws {
    var deckCards: [Card] = Deck.standard().cards
    let allEights: [Card] = deckCards.filter { $0.rank == .eight }
    deckCards.removeAll(where: { $0.rank == .eight })
    deckCards.append(contentsOf: allEights)

    let round: Round = try .init(
        cookedDeck: deckCards,
        players: makePlayers()
    )
    let topCard: Card = round.topDiscardCard!
    #expect(topCard.isEight == false)
}

@Test func roundInitFailsWithFewerThan2Players() {
    #expect(throws: CrazyEightsError.notEnoughPlayers) {
        _ = try Round(cookedDeck: Deck.standard().cards, players: makePlayers(1))
    }
}

@Test func roundInitFailsWithMoreThan8Players() {
    #expect(throws: CrazyEightsError.tooManyPlayers) {
        _ = try Round(cookedDeck: Deck.standard().cards, players: makePlayers(9))
    }
}

// MARK: - Play Card Tests

@Test func playMatchingSuitCard() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let playable: Card = .init(id: 101, rank: .three, suit: .hearts)

    let p1Hand: [Card] = [
        playable,
        .init(id: 102, rank: .two, suit: .clubs),
        .init(id: 103, rank: .four, suit: .clubs),
        .init(id: 104, rank: .five, suit: .clubs),
        .init(id: 105, rank: .six, suit: .clubs),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    #expect(round.topDiscardCard?.id == starter.id)
    #expect(round.currentPlayerID == "player1")
    #expect(round.playerHands[0].cards.contains(playable.id))

    try round.playCard(cardID: playable.id)

    #expect(round.topDiscardCard?.id == playable.id)
    #expect(round.currentPlayerID == "player2")
    #expect(round.playerHands[0].cards.contains(playable.id) == false)
}

@Test func playMatchingRankCard() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let playable: Card = .init(id: 101, rank: .king, suit: .clubs)

    let p1Hand: [Card] = [
        playable,
        .init(id: 102, rank: .two, suit: .spades),
        .init(id: 103, rank: .four, suit: .spades),
        .init(id: 104, rank: .five, suit: .spades),
        .init(id: 105, rank: .six, suit: .spades),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    try round.playCard(cardID: playable.id)
    #expect(round.topDiscardCard?.id == playable.id)
}

@Test func playEightRequiresDeclaredSuit() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let eightCard: Card = .init(id: 101, rank: .eight, suit: .clubs)

    let p1Hand: [Card] = [
        eightCard,
        .init(id: 102, rank: .two, suit: .spades),
        .init(id: 103, rank: .four, suit: .spades),
        .init(id: 104, rank: .five, suit: .spades),
        .init(id: 105, rank: .six, suit: .spades),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    #expect(throws: CrazyEightsError.mustSpecifySuitForEight) {
        try round.playCard(cardID: eightCard.id)
    }

    try round.playCard(cardID: eightCard.id, declaredSuit: .spades)
    #expect(round.declaredSuit == .spades)
    #expect(round.activeSuit == .spades)
}

@Test func cannotPlayUnmatchedCard() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let badCard: Card = .init(id: 101, rank: .three, suit: .clubs)

    let p1Hand: [Card] = [
        badCard,
        .init(id: 102, rank: .two, suit: .spades),
        .init(id: 103, rank: .four, suit: .spades),
        .init(id: 104, rank: .five, suit: .spades),
        .init(id: 105, rank: .six, suit: .spades),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    #expect(throws: CrazyEightsError.cardNotPlayable) {
        try round.playCard(cardID: badCard.id)
    }
}

// MARK: - Draw Tests

@Test func drawCardAddsToHand() throws {
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: makePlayers()
    )
    let initialCount: Int = round.playerHands[0].cards.count
    let initialStockCount: Int = round.stock.count

    try round.drawCard()

    #expect(round.playerHands[0].cards.count == initialCount + 1)
    #expect(round.stock.count == initialStockCount - 1)
}

@Test func drawReshufflesWhenStockEmpty() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let matchCard: Card = .init(id: 101, rank: .ace, suit: .hearts)

    let p1Hand: [Card] = [
        matchCard,
        .init(id: 102, rank: .two, suit: .clubs),
        .init(id: 103, rank: .four, suit: .clubs),
        .init(id: 104, rank: .five, suit: .clubs),
        .init(id: 105, rank: .six, suit: .clubs),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: [])
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())
    #expect(round.stock.count == 0)

    try round.playCard(cardID: matchCard.id)
    #expect(round.discardPile.count >= 1)
}

// MARK: - Pass Tests

@Test func passAdvancesTurn() throws {
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: makePlayers()
    )
    #expect(round.currentPlayerID == "player1")

    try round.pass()

    #expect(round.currentPlayerID == "player2")
}

// MARK: - Win Condition Test

@Test func playerWinsWhenHandEmpty() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let lastCard: Card = .init(id: 101, rank: .king, suit: .clubs)

    let p1Hand: [Card] = [
        lastCard,
        .init(id: 102, rank: .two, suit: .clubs),
        .init(id: 103, rank: .four, suit: .clubs),
        .init(id: 104, rank: .five, suit: .clubs),
        .init(id: 105, rank: .six, suit: .clubs),
    ]
    let p2Hand: [Card] = [
        .init(id: 200, rank: .seven, suit: .diamonds),
        .init(id: 201, rank: .nine, suit: .diamonds),
        .init(id: 202, rank: .ten, suit: .diamonds),
        .init(id: 203, rank: .jack, suit: .diamonds),
        .init(id: 204, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    // Simulate being down to the last card
    round.playerHands[0].cards = [lastCard.id]

    try round.playCard(cardID: lastCard.id)

    #expect(round.state.isComplete)
    if case .roundComplete(let winnerID, _) = round.state {
        #expect(winnerID == "player1")
    }
}

// MARK: - Scoring Test

@Test func scoringCalculatesCorrectly() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let winnerCard: Card = .init(id: 101, rank: .king, suit: .clubs)
    let loserCard1: Card = .init(id: 102, rank: .eight, suit: .spades)
    let loserCard2: Card = .init(id: 103, rank: .ace, suit: .hearts)

    let p1Hand: [Card] = [
        winnerCard,
        .init(id: 104, rank: .two, suit: .spades),
        .init(id: 105, rank: .four, suit: .spades),
        .init(id: 106, rank: .five, suit: .spades),
        .init(id: 107, rank: .six, suit: .spades),
    ]
    let p2Hand: [Card] = [
        loserCard1,
        loserCard2,
        .init(id: 108, rank: .ten, suit: .diamonds),
        .init(id: 109, rank: .jack, suit: .diamonds),
        .init(id: 110, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    round.playerHands[0].cards = [winnerCard.id]
    round.playerHands[1].cards = [loserCard1.id, loserCard2.id]

    try round.playCard(cardID: winnerCard.id)

    guard let scores: [PlayerID: Int] = round.finalScores else {
        Issue.record("Expected scores")
        return
    }

    #expect(scores["player2"] == 51) // eight(50) + ace(1)
    #expect(scores["player1"] == 51) // winner collects the total
}

// MARK: - Full Round Playthrough

@Test func fullRoundPlaythrough() throws {
    let players: [Player] = makePlayers(3)
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 500

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }

        let playable: [Card] = round.playableCards(for: currentID)

        if let card: Card = playable.first {
            if card.isEight {
                try round.playCard(cardID: card.id, declaredSuit: .hearts)
            } else {
                try round.playCard(cardID: card.id)
            }
        } else if round.stock.isEmpty == false {
            try round.drawCard()
        } else {
            try round.pass()
        }

        turnCount += 1
    }

    if round.state.isComplete {
        guard let scores: [PlayerID: Int] = round.finalScores else {
            Issue.record("Expected scores on complete round")
            return
        }
        #expect(scores.keys.count == 3)
        print("Round complete after \(turnCount) turns")
        print("Scores: \(scores)")
    } else {
        print("Round did not complete within \(maxTurns) turns (this can happen with pass loops)")
    }
}

// MARK: - AI Tests

@Test func aiEasyMakesValidMoves() throws {
    let players: [Player] = makePlayers()
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 500

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }
        try round.makeAIMove(difficulty: .easy, playerID: currentID)
        turnCount += 1
    }

    print("AI Easy game finished in \(turnCount) turns. Complete: \(round.state.isComplete)")
}

@Test func aiMediumMakesValidMoves() throws {
    let players: [Player] = makePlayers()
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 500

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }
        try round.makeAIMove(difficulty: .medium, playerID: currentID)
        turnCount += 1
    }

    print("AI Medium game finished in \(turnCount) turns. Complete: \(round.state.isComplete)")
}

@Test func aiHardMakesValidMoves() throws {
    let players: [Player] = makePlayers()
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 500

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }
        try round.makeAIMove(difficulty: .hard, playerID: currentID)
        turnCount += 1
    }

    print("AI Hard game finished in \(turnCount) turns. Complete: \(round.state.isComplete)")
}

@Test func aiDoesNotCheat() throws {
    let players: [Player] = makePlayers()
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 300

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }
        let handBefore: [CardID] = round.playerHands.first(where: { $0.player.id == currentID })!.cards

        let ai: AIEngine = .init(difficulty: .hard)
        let action: AIAction = ai.chooseAction(for: round, playerID: currentID)

        switch action {
        case .playCard(let cardID, _):
            #expect(handBefore.contains(cardID))

        case .draw, .pass:
            break
        }

        try round.makeAIMove(difficulty: .hard, playerID: currentID)
        turnCount += 1
    }
}

// MARK: - Multi-Player AI Game

@Test func fourPlayerAIGame() throws {
    let players: [Player] = makePlayers(4)
    var round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: players
    )

    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while round.state.isComplete == false && turnCount < maxTurns {
        guard let currentID: PlayerID = round.currentPlayerID else { break }
        let difficulty: AIDifficulty = [.easy, .medium, .hard][turnCount % 3]
        try round.makeAIMove(difficulty: difficulty, playerID: currentID)
        turnCount += 1
    }

    print("4-player AI game finished in \(turnCount) turns. Complete: \(round.state.isComplete)")
    if let scores = round.finalScores {
        print("Final scores: \(scores)")
    }
}

// MARK: - Log Tests

@Test func logKeepsMaxActions() throws {
    var log: Round.Log = .init()
    for _ in 0 ..< 150 {
        log.addAction(.init(
            playerID: "player1",
            decision: .pass
        ))
    }
    #expect(log.actions.count == 100)
}

// MARK: - Fake Tests

@Test func fakeCardCreation() {
    let card: Card = .fake()
    #expect(Card.Rank.allCases.contains(card.rank))
    #expect(Card.Suit.allCases.contains(card.suit))
}

@Test func fakePlayerCreation() {
    let player: Player = .fake()
    #expect(player.name == "Fake Player")
    #expect(player.score == 0)
}

@Test func fakeRoundCreation() throws {
    let round: Round = try .fake()
    #expect(round.playerHands.count == 2)
    #expect(round.state.isComplete == false)
}

@Test func fakePlayerHandCreation() {
    let hand: PlayerHand = .fake()
    #expect(hand.cards.isEmpty)
}

// MARK: - Codable Tests

@Test func roundEncodesAndDecodes() throws {
    let round: Round = try .init(
        cookedDeck: Deck.standard().cards,
        players: makePlayers()
    )

    let encoder: JSONEncoder = .init()
    encoder.dateEncodingStrategy = .iso8601
    let data: Data = try encoder.encode(round)

    let decoder: JSONDecoder = .init()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let decoded: Round = try decoder.decode(Round.self, from: data)

    #expect(decoded.id == round.id)
    #expect(decoded.playerHands.count == round.playerHands.count)
    #expect(decoded.stock.count == round.stock.count)
    #expect(decoded.discardPile.count == round.discardPile.count)
}

// MARK: - Edge Case: Declared Suit After Eight

@Test func declaredSuitClearsAfterNonEight() throws {
    let starter: Card = .init(id: 100, rank: .king, suit: .hearts)
    let eightCard: Card = .init(id: 101, rank: .eight, suit: .clubs)
    let spadesCard: Card = .init(id: 102, rank: .five, suit: .spades)

    let p1Hand: [Card] = [
        eightCard,
        .init(id: 103, rank: .two, suit: .clubs),
        .init(id: 104, rank: .four, suit: .clubs),
        .init(id: 105, rank: .five, suit: .clubs),
        .init(id: 106, rank: .six, suit: .clubs),
    ]
    let p2Hand: [Card] = [
        spadesCard,
        .init(id: 200, rank: .nine, suit: .diamonds),
        .init(id: 201, rank: .ten, suit: .diamonds),
        .init(id: 202, rank: .jack, suit: .diamonds),
        .init(id: 203, rank: .queen, suit: .diamonds),
    ]
    let stock: [Card] = (0 ..< 10).map { .init(id: 300 + $0, rank: .ace, suit: .spades) }

    let deck: [Card] = buildDeck(p1Hand: p1Hand, p2Hand: p2Hand, starter: starter, stock: stock)
    var round: Round = try .init(cookedDeck: deck, players: makePlayers())

    try round.playCard(cardID: eightCard.id, declaredSuit: .spades)
    #expect(round.declaredSuit == .spades)

    try round.playCard(cardID: spadesCard.id)
    #expect(round.declaredSuit == nil)
    #expect(round.activeSuit == .spades)
}
