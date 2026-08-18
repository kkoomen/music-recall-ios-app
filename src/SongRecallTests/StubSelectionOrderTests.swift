import XCTest
@testable import SongRecall

/// Pins the deterministic selection order used by UI-test stub mode
/// (`-uitest-library ready`, seed 0). The UI tests depend on this exact
/// order to type known answers.
@MainActor
final class StubSelectionOrderTests: XCTestCase {
    func testReadyStubFirstRoundTitle() {
        let engine = QuizEngine(
            catalog: StubMediaLibrary.tracks,
            random: SeededRandomSource(seed: 0),
            clock: FakeClock()
        )
        XCTAssertEqual(engine.session.rounds.count, 3)
        let titles = engine.session.rounds.map(\.track.title)
        XCTAssertEqual(Set(titles).count, 3, "Round selection must be unique")
        // Order is deterministic for seed 0: Gamma, Beta, Alpha.
        XCTAssertEqual(engine.session.rounds.map(\.track.title), ["Gamma Song", "Beta Song", "Alpha Song"])
    }
}
