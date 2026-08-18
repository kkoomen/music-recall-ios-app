import XCTest
@testable import SongRecall

/// View-model level tests for the debounced, catalog-wide autocomplete
/// and keyboard return handling.
@MainActor
final class QuizViewModelSuggestionTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String) -> Track {
        Track(id: id, title: title, artist: "Artist", album: "Album", assetURL: url)
    }

    private func makeViewModel(catalog: [Track]) -> QuizViewModel {
        let engine = QuizEngine(
            catalog: catalog,
            random: SeededRandomSource(seed: 0),
            clock: FakeClock()
        )
        return QuizViewModel(
            engine: engine,
            audioPlayer: StubAudioPlayer(),
            catalog: catalog,
            onFinish: { _ in }
        )
    }

    func testSuggestionsStayEmptyUntilDebounceElapses() async throws {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = "gam"
        vm.guessDidChange()

        // Before the 400ms debounce elapses, nothing is published.
        XCTAssertTrue(vm.suggestions.isEmpty)

        try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(vm.suggestions.first?.track.id, 3) // Gamma Song
    }

    func testSearchesFullCatalogBeyondSessionSelection() async throws {
        let catalog = (1...12).map { track(UInt64($0), "Song \($0)") }
        let engine = QuizEngine(
            catalog: catalog,
            random: SeededRandomSource(seed: 0),
            clock: FakeClock()
        )
        // The session only holds 10 of the 12 catalog tracks.
        let sessionIds = Set(engine.session.rounds.map(\.track.id))
        let excluded = try XCTUnwrap(catalog.first { !sessionIds.contains($0.id) })

        let vm = QuizViewModel(
            engine: engine,
            audioPlayer: StubAudioPlayer(),
            catalog: catalog,
            onFinish: { _ in }
        )
        vm.start()
        vm.guess = excluded.title
        vm.guessDidChange()
        try await Task.sleep(for: .milliseconds(600))

        // A track outside the session selection is still suggestable.
        XCTAssertEqual(vm.suggestions.first?.track.id, excluded.id)
    }

    func testEmptyQueryKeepsDropdownOpen() async throws {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = "gam"
        vm.guessDidChange()
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertFalse(vm.suggestions.isEmpty)

        // Clearing the input keeps the last results so enter can pick
        // the first suggestion.
        vm.guess = ""
        vm.guessDidChange()
        XCTAssertFalse(vm.suggestions.isEmpty)
        XCTAssertEqual(vm.suggestions.first?.track.id, 3)
    }

    func testSubmitFromKeyboardSelectsFirstSuggestionWhenFieldEmpty() async throws {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = "gam"
        vm.guessDidChange()
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(vm.suggestions.first?.track.id, 3) // Gamma Song = round 1 answer

        vm.guess = ""
        vm.guessDidChange()
        vm.submitFromKeyboard()

        XCTAssertEqual(vm.feedback, .correct(points: 80, isFast: true))
    }

    func testSubmitFromKeyboardDoesNothingWhenEmptyAndNoDropdown() {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = ""
        vm.submitFromKeyboard()

        // Pressing return with an empty field must never cause a wrong answer.
        XCTAssertEqual(vm.feedback, .none)
        XCTAssertTrue(vm.roundIsActive)
    }

    func testSubmitFromKeyboardSubmitsNonEmptyGuess() {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = "Not A Real Title"
        vm.submitFromKeyboard()

        XCTAssertEqual(vm.feedback, .wrong(points: -5))
    }

    func testRunningScoreNeverGoesBelowZero() {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        XCTAssertEqual(vm.score, 0)

        vm.skip() // -10, clamps to 0
        XCTAssertEqual(vm.score, 0)
        vm.advance()

        vm.guess = "wrong guess"
        vm.submitFromKeyboard() // -5, clamps to 0
        XCTAssertEqual(vm.score, 0)
    }

    func testSettlingARoundClearsSuggestions() async throws {
        let vm = makeViewModel(catalog: StubMediaLibrary.tracks)
        vm.start()
        vm.guess = "gam"
        vm.guessDidChange()
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertFalse(vm.suggestions.isEmpty)

        vm.skip()
        XCTAssertTrue(vm.suggestions.isEmpty)
    }
}
