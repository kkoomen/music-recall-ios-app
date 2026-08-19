import XCTest
@testable import SongRecall

final class OptionGeneratorTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String, artist: String = "Artist") -> Track {
        Track(id: id, title: title, artist: artist, album: "Album", assetURL: url)
    }

    private func catalog(_ count: Int) -> [Track] {
        (1...count).map { track(UInt64($0), "Song \($0)") }
    }

    func testFiveOptionsIncludeCorrectTrack() {
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct] + catalog(9),
            random: SeededRandomSource(seed: 7)
        )
        XCTAssertEqual(options.count, 5)
        XCTAssertTrue(options.contains { $0.id == correct.id })
    }

    func testOptionsAreUniqueTrackIDs() {
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct] + catalog(9),
            random: SeededRandomSource(seed: 7)
        )
        XCTAssertEqual(Set(options.map(\.id)).count, options.count)
    }

    func testOptionOrderIsDeterministicPerSeed() {
        let correct = track(1, "Target Song")
        let source = [correct] + catalog(9)
        let first = OptionGenerator.options(
            for: correct,
            from: source,
            random: SeededRandomSource(seed: 42)
        )
        let second = OptionGenerator.options(
            for: correct,
            from: source,
            random: SeededRandomSource(seed: 42)
        )
        XCTAssertEqual(first.map(\.id), second.map(\.id))
    }

    func testDifferentSeedsCanReorderOptions() {
        let correct = track(1, "Target Song")
        let source = [correct] + catalog(9)
        let first = OptionGenerator.options(
            for: correct,
            from: source,
            random: SeededRandomSource(seed: 1)
        )
        let second = OptionGenerator.options(
            for: correct,
            from: source,
            random: SeededRandomSource(seed: 2)
        )
        XCTAssertNotEqual(first.map(\.id), second.map(\.id))
    }

    func testFewerThanFiveCatalogTracksShrinksOptions() {
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct, track(2, "Song 2"), track(3, "Song 3")],
            random: SeededRandomSource(seed: 0)
        )
        XCTAssertEqual(options.count, 3)
        XCTAssertTrue(options.contains { $0.id == correct.id })
    }

    func testCorrectTrackAlwaysPresentEvenWithSingleTrackCatalog() {
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct],
            random: SeededRandomSource(seed: 0)
        )
        XCTAssertEqual(options.map(\.id), [correct.id])
    }

    func testDecoysExcludeTracksSharingTheCorrectTitle() {
        // Track 2 shares the normalized title with the correct track and
        // must never appear as a decoy.
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct, track(2, "target song"), track(3, "Song 3"), track(4, "Song 4"),
                   track(5, "Song 5"), track(6, "Song 6")],
            random: SeededRandomSource(seed: 0)
        )
        XCTAssertEqual(options.count, 5)
        XCTAssertFalse(options.contains { $0.id == 2 })
    }

    func testDuplicateDecoyTitlesAreDeduplicated() {
        // Tracks 2 and 3 share a title; only one of them may appear as a
        // decoy so the player never sees identical options.
        let correct = track(1, "Target Song")
        let source = [
            correct,
            track(2, "Same Title"),
            track(3, "same title"),
            track(4, "Song 4"),
            track(5, "Song 5"),
            track(6, "Song 6"),
        ]
        let options = OptionGenerator.options(
            for: correct,
            from: source,
            random: SeededRandomSource(seed: 0)
        )
        let decoyIDs = options.filter { $0.id != correct.id }.map(\.id)
        XCTAssertEqual(decoyIDs.count, Set(decoyIDs).count)
        let sameTitleIDs = decoyIDs.filter { $0 == 2 || $0 == 3 }
        XCTAssertLessThanOrEqual(sameTitleIDs.count, 1)
    }

    func testLimitOneReturnsOnlyTheCorrectTrack() {
        let correct = track(1, "Target Song")
        let options = OptionGenerator.options(
            for: correct,
            from: [correct] + catalog(9),
            random: SeededRandomSource(seed: 0),
            limit: 1
        )
        XCTAssertEqual(options.map(\.id), [correct.id])
    }
}
