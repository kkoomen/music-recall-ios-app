import Foundation
@testable import SongRecall

/// Reference-type monotonic clock whose value tests advance manually.
/// Test-only: confined to the main actor.
final class FakeClock: Clocking, @unchecked Sendable {
    var now: TimeInterval

    init(now: TimeInterval = 0) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now += seconds
    }
}
