import Foundation

extension [Card] {
    public var debugDescription: String {
        map { $0.debugDescription }.joined(separator: " ")
    }

    public var totalScoringValue: Int {
        reduce(0) { $0 + $1.scoringValue }
    }
}
