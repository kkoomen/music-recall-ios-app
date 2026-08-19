import XCTest
@testable import SongRecall

/// Easy-mode behavior at the view-model level: option generation,
/// identity-matched picks, highlight state, and the 3-second fast
/// window flowing through the engine configuration.
@MainActor
final class QuizViewModelModeTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String) -> Track {
        Track(id: id, title: title, artist: "Artist \(id)", album: "Album", assetURL: url)
    }

    private func makeViewModel(catalog: [Track], mode: QuizMode) -> QuizViewModel {
        let engine = QuizEngine(
            catalog: catalog,
            configuration: QuizConfiguration(mode: mode),
            random: SeededRandomSource(seed: 0),
            clock: FakeClock()
        )
        return QuizViewModel(
            engine: engine,
            audioPlayer: StubAudioPlayer(),
            catalog: catalog,
            random: SeededRandomSource(seed: 0),
            onFinish: { _ in }
        )
    }

    private func catalog() -> [Track] {
        (1...12).map { track(UInt64($0), "Song \($0)") }
    }

    func testEasyModeStartBuildsFiveOptionsIncludingTheAnswer() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        XCTAssertEqual(vm.options.count, 5)
        XCTAssertTrue(vm.options.contains { $0.id == vm.correctOptionID })
        XCTAssertEqual(vm.correctOptionID, vm.currentTrack?.id)
    }

    func testHardModeHasNoOptions() {
        let vm = makeViewModel(catalog: catalog(), mode: .hard)
        vm.start()

        XCTAssertTrue(vm.options.isEmpty)
        XCTAssertFalse(vm.isEasyMode)
    }

    func testSelectingCorrectOptionSettlesRoundFast() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        let correct = try! XCTUnwrap(vm.options.first { $0.id == vm.correctOptionID })
        vm.selectOption(correct)

        // Elapsed 0: (10 + 30) x 2 = 80 with the easy 3s window.
        XCTAssertEqual(vm.feedback, .correct(points: 80, isFast: true))
        XCTAssertEqual(vm.selectedOptionID, correct.id)
        XCTAssertFalse(vm.roundIsActive)
    }

    func testEasyWindowIsThreeSecondsNotFive() {
        let clock = FakeClock()
        let engine = QuizEngine(
            catalog: catalog(),
            configuration: QuizConfiguration(mode: .easy),
            random: SeededRandomSource(seed: 0),
            clock: clock
        )
        let vm = QuizViewModel(
            engine: engine,
            audioPlayer: StubAudioPlayer(),
            catalog: catalog(),
            random: SeededRandomSource(seed: 0),
            onFinish: { _ in }
        )
        vm.start()

        // 4 seconds later the 2x window is gone in easy mode (would
        // still be active in hard mode).
        clock.advance(by: 4)
        let correct = try! XCTUnwrap(vm.options.first { $0.id == vm.correctOptionID })
        vm.selectOption(correct)

        XCTAssertEqual(vm.feedback, .correct(points: 36, isFast: false))
    }

    func testSelectingWrongOptionSettlesAndKeepsHighlightState() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        let wrong = try! XCTUnwrap(vm.options.first { $0.id != vm.correctOptionID })
        vm.selectOption(wrong)

        XCTAssertEqual(vm.feedback, .wrong(points: -5))
        XCTAssertEqual(vm.selectedOptionID, wrong.id)
        // Options stay visible so the view can highlight them.
        XCTAssertEqual(vm.options.count, 5)
    }

    func testSelectingAfterSettleIsIgnored() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        let wrong = try! XCTUnwrap(vm.options.first { $0.id != vm.correctOptionID })
        vm.selectOption(wrong)
        XCTAssertEqual(vm.feedback, .wrong(points: -5))

        let correct = try! XCTUnwrap(vm.options.first { $0.id == vm.correctOptionID })
        vm.selectOption(correct)
        XCTAssertEqual(vm.feedback, .wrong(points: -5), "Late pick must not change the outcome")
        XCTAssertEqual(vm.score, 0)
    }

    func testNextRoundResetsSelectionAndOptions() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        let wrong = try! XCTUnwrap(vm.options.first { $0.id != vm.correctOptionID })
        vm.selectOption(wrong)
        vm.advance()

        XCTAssertNil(vm.selectedOptionID)
        XCTAssertEqual(vm.options.count, 5)
        XCTAssertTrue(vm.options.contains { $0.id == vm.correctOptionID })
    }

    func testEasyModeSkipKeepsPenalty() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        vm.skip()
        XCTAssertEqual(vm.feedback, .skipped(points: -10))
        XCTAssertEqual(vm.score, 0) // clamped
    }

    func testEasyModeIsolationFromHardInputPaths() {
        let vm = makeViewModel(catalog: catalog(), mode: .easy)
        vm.start()

        vm.guess = "Not A Real Title"
        vm.submitFromKeyboard()
        XCTAssertEqual(vm.feedback, .none, "Typed answers must be ignored in easy mode")
        XCTAssertTrue(vm.roundIsActive)
    }
}
