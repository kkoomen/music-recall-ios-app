import Foundation

/// Wires selection randomness and a monotonic clock into the pure
/// session state machine. Thin and main-actor confined by usage.
final class QuizEngine {
    let configuration: QuizConfiguration
    private let clock: Clocking
    private(set) var session: QuizSession

    /// Selects `roundCount` unique shuffled tracks, or every track when
    /// the catalog is smaller. Empty catalog yields a session that
    /// cannot start.
    init(
        catalog: [Track],
        configuration: QuizConfiguration = .default,
        random: RandomSource,
        clock: Clocking
    ) {
        self.configuration = configuration
        self.clock = clock
        let count = min(max(configuration.roundCount, 0), catalog.count)
        let rounds = random.shuffled(catalog)
            .prefix(count)
            .map { QuizRound(track: $0) }
        self.session = QuizSession(configuration: configuration, rounds: Array(rounds))
    }

    var state: QuizState { session.state }
    var currentRound: QuizRound? { session.currentRound }
    /// Monotonic elapsed seconds from the injected clock, used by the
    /// UI timer display.
    var now: TimeInterval { clock.now }

    @discardableResult
    func begin() -> QuizState {
        session.begin(now: clock.now)
    }

    @discardableResult
    func submitAnswer(_ guess: String) -> RoundOutcome? {
        session.submitAnswer(guess, now: clock.now)
    }

    @discardableResult
    func submitOption(trackID: UInt64) -> RoundOutcome? {
        session.submitOption(trackID: trackID, now: clock.now)
    }

    @discardableResult
    func skip() -> RoundOutcome? {
        session.skip()
    }

    @discardableResult
    func interrupt() -> RoundOutcome? {
        session.interrupt()
    }

    @discardableResult
    func markTimedOutIfNeeded() -> RoundOutcome? {
        session.markTimedOutIfNeeded(now: clock.now)
    }

    @discardableResult
    func advance() -> QuizState {
        session.advance(now: clock.now)
    }
}
