import Foundation

/// Monotonic time source. `now` is seconds since an arbitrary fixed
/// epoch and must never jump backwards (no wall-clock alignment).
protocol Clocking: Sendable {
    var now: TimeInterval { get }
}
