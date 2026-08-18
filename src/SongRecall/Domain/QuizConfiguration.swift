import Foundation

/// Tunable quiz parameters. Defaults match the MVP rules.
struct QuizConfiguration: Equatable, Sendable {
    var roundCount: Int
    var roundDuration: TimeInterval

    init(roundCount: Int = 10, roundDuration: TimeInterval = 30) {
        self.roundCount = roundCount
        self.roundDuration = roundDuration
    }

    static let `default` = QuizConfiguration()
}
