import Foundation

/// Pure builders for the user-visible feedback strings, kept here so
/// the exact wording (including interpolated point values) is
/// unit-testable.
enum FeedbackStrings {
    static func correct(points: Int, isFast: Bool) -> String {
        isFast
            ? "You're fast! 2x multiplier, plus \(points) points"
            : "Correct! +\(points) points"
    }

    static func wrong(points: Int) -> String {
        "Not this time (\(points))"
    }

    static func skipped(points: Int) -> String {
        "Skipped (\(points))"
    }

    static let timedOut = "Time's up"
    static let interrupted = "Playback was interrupted"
}
