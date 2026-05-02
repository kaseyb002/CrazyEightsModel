import Foundation

public enum CrazyEightsError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notPlayersTurn
    case roundIsComplete
    case cardNotInPlayersHand
    case cardNotPlayable
    case mustSpecifySuitForEight
    case stockAndDiscardPileEmpty
    case playerNotFound
    case deckIsEmpty
}
