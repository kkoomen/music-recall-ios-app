import Foundation

/// Terminal result of one round. `correct` carries the elapsed seconds
/// used for weighted scoring.
enum RoundOutcome: Equatable, Sendable {
    case correct(elapsed: TimeInterval)
    case wrong
    case skipped
    case timedOut
    case interrupted
}
