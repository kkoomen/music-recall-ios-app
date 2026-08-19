import Foundation

/// Tunable quiz parameters. Defaults match the MVP rules.
struct QuizConfiguration: Equatable, Sendable {
    var roundCount: Int
    var roundDuration: TimeInterval
    /// Difficulty mode; easy presents five options, hard is free text.
    var mode: QuizMode

    init(roundCount: Int = 10, roundDuration: TimeInterval = 30, mode: QuizMode = .hard) {
        self.roundCount = roundCount
        self.roundDuration = roundDuration
        self.mode = mode
    }

    /// Seconds of round time within which a correct answer earns the
    /// 2x multiplier. Easy and expert modes reward a quick pick with a
    /// tighter 3-second window (27 or more seconds remaining on the
    /// clock); hard mode keeps the 5-second window.
    var fastThreshold: TimeInterval {
        mode == .hard ? 5 : 3
    }

    static let `default` = QuizConfiguration()
}
