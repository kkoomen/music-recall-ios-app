import XCTest
@testable import SongRecall

final class QuizEngineTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func makeTrack(id: UInt64) -> Track {
        Track(id: id, title: "Track \(id)", artist: "Artist", album: "Album", assetURL: url)
    }

    private func makeCatalog(count: Int) -> [Track] {
        (1...count).map { makeTrack(id: UInt64($0)) }
    }

    func testSelectsTenUniqueTracksFromLargeCatalog() {
        let engine = QuizEngine(
            catalog: makeCatalog(count: 50),
            random: SeededRandomSource(seed: 7),
            clock: FakeClock()
        )
        let rounds = engine.session.rounds
        XCTAssertEqual(rounds.count, 10)
        let ids = Set(rounds.map(\.track.id))
        XCTAssertEqual(ids.count, 10)
    }

    func testUsesAllTracksWhenCatalogIsSmallerThanTen() {
        let engine = QuizEngine(
            catalog: makeCatalog(count: 4),
            random: SeededRandomSource(seed: 7),
            clock: FakeClock()
        )
        XCTAssertEqual(engine.session.rounds.count, 4)
    }

    func testSameSeedProducesSameSelection() {
        let a = QuizEngine(catalog: makeCatalog(count: 20), random: SeededRandomSource(seed: 42), clock: FakeClock())
        let b = QuizEngine(catalog: makeCatalog(count: 20), random: SeededRandomSource(seed: 42), clock: FakeClock())
        XCTAssertEqual(a.session.rounds.map(\.track.id), b.session.rounds.map(\.track.id))
    }

    func testDifferentSeedProducesDifferentSelection() {
        let a = QuizEngine(catalog: makeCatalog(count: 20), random: SeededRandomSource(seed: 1), clock: FakeClock())
        let b = QuizEngine(catalog: makeCatalog(count: 20), random: SeededRandomSource(seed: 2), clock: FakeClock())
        XCTAssertNotEqual(a.session.rounds.map(\.track.id), b.session.rounds.map(\.track.id))
    }

    func testEmptyCatalogCannotStart() {
        let engine = QuizEngine(catalog: [], random: SeededRandomSource(seed: 0), clock: FakeClock())
        XCTAssertEqual(engine.begin(), .notStarted)
    }

    func testFullSessionRunsWithEngineClock() {
        let clock = FakeClock()
        let engine = QuizEngine(
            catalog: makeCatalog(count: 3),
            configuration: QuizConfiguration(roundCount: 3, roundDuration: 30),
            random: SeededRandomSource(seed: 5),
            clock: clock
        )
        _ = engine.begin()
        clock.advance(by: 4)
        guard let round = engine.currentRound else { return XCTFail() }
        _ = engine.submitAnswer(round.track.title)
        _ = engine.advance()
        clock.advance(by: 2)
        guard let second = engine.currentRound else { return XCTFail() }
        _ = engine.submitAnswer(second.track.title)
        _ = engine.advance()
        clock.advance(by: 1)
        _ = engine.skip()
        let state = engine.advance()

        guard case .finished(let result) = state else {
            return XCTFail("Expected finished")
        }
        XCTAssertEqual(result.rounds.count, 3)
        XCTAssertEqual(result.correctCount, 2)
        XCTAssertEqual(result.fastestCorrectElapsed, 2)
    }

    func testRoundsNeverRepeatTracksAcrossSession() {
        let engine = QuizEngine(
            catalog: makeCatalog(count: 12),
            configuration: QuizConfiguration(roundCount: 10),
            random: SeededRandomSource(seed: 99),
            clock: FakeClock()
        )
        let ids = engine.session.rounds.map(\.track.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
