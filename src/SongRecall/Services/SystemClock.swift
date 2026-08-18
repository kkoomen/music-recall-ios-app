import Foundation

/// Monotonic clock backed by `ContinuousClock`, measured from the
/// moment of creation. Never aligned to wall-clock time.
struct SystemClock: Clocking {
    private let start = ContinuousClock.now

    var now: TimeInterval {
        let elapsed = ContinuousClock.now - start
        return Double(elapsed.components.seconds)
            + Double(elapsed.components.attoseconds) / 1e18
    }
}
