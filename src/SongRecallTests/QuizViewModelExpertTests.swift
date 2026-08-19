import XCTest
@testable import SongRecall

/// Sample-mode view-model behavior: multiple-choice mechanics identical
/// to easy, the first 1-second sample plays automatically at round
/// start (free of charge), and the same random part can be replayed up
/// to three more times per round (reset every round).
@MainActor
final class QuizViewModelExpertTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    private func track(_ id: UInt64, _ title: String) -> Track {
        Track(id: id, title: title, artist: "Artist \(id)", album: "Album", assetURL: url)
    }

    private func catalog() -> [Track] {
        (1...12).map { track(UInt64($0), "Song \($0)") }
    }

    private func makeViewModel(
        catalog: [Track]? = nil,
        player: FakeAudioPlayer = FakeAudioPlayer(),
        mode: QuizMode = .expert
    ) -> (QuizViewModel, FakeAudioPlayer) {
        let engine = QuizEngine(
            catalog: catalog ?? self.catalog(),
            configuration: QuizConfiguration(mode: mode),
            random: SeededRandomSource(seed: 0),
            clock: FakeClock()
        )
        let vm = QuizViewModel(
            engine: engine,
            audioPlayer: player,
            catalog: catalog ?? self.catalog(),
            random: SeededRandomSource(seed: 0),
            onFinish: { _ in }
        )
        return (vm, player)
    }

    func testExpertRoundAutoPlaysFirstSampleWithoutConsumingAttempt() async throws {
        let (vm, player) = makeViewModel()
        vm.start()

        // Multiple-choice mechanics identical to easy mode.
        XCTAssertEqual(vm.options.count, 5)
        XCTAssertTrue(vm.options.contains { $0.id == vm.correctOptionID })
        // The first sample plays immediately and for free.
        XCTAssertEqual(vm.sampleAttemptsRemaining, 3)
        XCTAssertTrue(vm.isSamplePlaying)
        try await waitUntil { player.events.contains(.play) }
        XCTAssertEqual(player.events.filter { $0 == .loadDuration(url) }.count, 1)

        // It stops itself after one second; the manual plays are intact.
        try await Task.sleep(for: .seconds(1.3))
        XCTAssertFalse(vm.isSamplePlaying)
        XCTAssertEqual(player.events.last, .stop)
        XCTAssertEqual(vm.sampleAttemptsRemaining, 3)
        XCTAssertTrue(vm.canPlaySample)
    }

    func testPlaySampleConsumesAttemptAndStopsAfterOneSecond() async throws {
        let (vm, player) = makeViewModel()
        vm.start()
        // Let the free automatic sample finish before pressing the button.
        try await Task.sleep(for: .seconds(1.3))

        vm.playSample()
        XCTAssertEqual(vm.sampleAttemptsRemaining, 2)
        XCTAssertTrue(vm.isSamplePlaying)
        try await waitUntil { player.events.contains(.play) }
        // The offset was picked during the automatic play; the manual
        // replay reuses it without another duration load.
        XCTAssertEqual(player.events.filter { $0 == .loadDuration(url) }.count, 1)

        try await Task.sleep(for: .seconds(1.3))
        XCTAssertFalse(vm.isSamplePlaying)
        XCTAssertEqual(player.events.last, .stop)
        XCTAssertFalse(player.isPlaying)
    }

    func testSampleReplaysTheSameRandomPart() async throws {
        let (vm, player) = makeViewModel()
        vm.start()
        try await Task.sleep(for: .seconds(1.3))

        vm.playSample()
        try await Task.sleep(for: .seconds(1.3))
        vm.playSample()
        try await Task.sleep(for: .seconds(1.3))

        // The duration is loaded exactly once per round: every press
        // replays the same part.
        XCTAssertEqual(player.events.filter { $0 == .loadDuration(url) }.count, 1)
        XCTAssertEqual(vm.sampleAttemptsRemaining, 1)
    }

    func testSampleLockedAfterThreeManualAttempts() async throws {
        let (vm, player) = makeViewModel()
        vm.start()
        try await Task.sleep(for: .seconds(1.3))

        for _ in 1...3 {
            vm.playSample()
            XCTAssertTrue(vm.isSamplePlaying)
            try await Task.sleep(for: .seconds(1.3))
        }
        XCTAssertEqual(vm.sampleAttemptsRemaining, 0)
        XCTAssertFalse(vm.canPlaySample)

        // A fourth press is ignored entirely.
        let playsBefore = player.events.filter { $0 == .play }.count
        vm.playSample()
        XCTAssertEqual(player.events.filter { $0 == .play }.count, playsBefore)
        XCTAssertEqual(vm.sampleAttemptsRemaining, 0)
    }

    func testPlaySampleIgnoredOnceRoundSettles() async throws {
        let (vm, player) = makeViewModel()
        vm.start()
        try await Task.sleep(for: .seconds(1.3))

        vm.playSample()
        try await Task.sleep(for: .seconds(1.3))

        let wrong = try XCTUnwrap(vm.options.first { $0.id != vm.correctOptionID })
        vm.selectOption(wrong)
        XCTAssertEqual(vm.feedback, .wrong(points: -5))

        let playsBefore = player.events.filter { $0 == .play }.count
        vm.playSample()
        XCTAssertEqual(player.events.filter { $0 == .play }.count, playsBefore)
    }

    func testSampleAttemptsResetOnNextRound() async throws {
        let (vm, player) = makeViewModel()
        vm.start()
        try await Task.sleep(for: .seconds(1.3))
        XCTAssertEqual(vm.sampleAttemptsRemaining, 3)

        vm.playSample()
        try await Task.sleep(for: .seconds(1.3))
        XCTAssertEqual(vm.sampleAttemptsRemaining, 2)

        let correct = try XCTUnwrap(vm.options.first { $0.id == vm.correctOptionID })
        vm.selectOption(correct)
        vm.advance()

        // The next round resets the attempts and auto-plays its sample.
        XCTAssertEqual(vm.sampleAttemptsRemaining, 3)
        XCTAssertTrue(vm.isSamplePlaying)
        try await Task.sleep(for: .seconds(1.3))
        XCTAssertFalse(vm.isSamplePlaying)

        vm.playSample()
        XCTAssertEqual(vm.sampleAttemptsRemaining, 2)
        XCTAssertTrue(vm.isSamplePlaying)
        XCTAssertFalse(player.events.isEmpty)
    }

    func testAutomaticSampleFailureSettlesRoundAsInterrupted() async throws {
        let player = FakeAudioPlayer()
        player.prepareError = .assetUnavailable
        let (vm, _) = makeViewModel(player: player)
        vm.start()

        // The free automatic play fails; the round settles as interrupted.
        let feedback = try await waitForFeedback(vm)
        XCTAssertEqual(feedback, .interrupted)
        XCTAssertFalse(vm.isSamplePlaying)
        XCTAssertEqual(vm.sampleAttemptsRemaining, 3)
    }

    func testEasyAndHardModesHaveNoSampleControls() {
        for mode in [QuizMode.easy, QuizMode.hard] {
            let (vm, player) = makeViewModel(mode: mode)
            vm.start()
            XCTAssertEqual(vm.sampleAttemptsRemaining, 0)
            XCTAssertFalse(vm.canPlaySample)
            let playsBefore = player.events.filter { $0 == .play }.count
            vm.playSample()
            // No sample playback: no duration load, no extra play.
            XCTAssertTrue(player.events.filter { $0 == .loadDuration(url) }.isEmpty)
            XCTAssertEqual(player.events.filter { $0 == .play }.count, playsBefore)
        }
    }

    // MARK: - Helpers

    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 2) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTFail("Condition not met within \(timeout)s")
    }

    private func waitForFeedback(_ vm: QuizViewModel) async throws -> QuizViewModel.Feedback {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if vm.feedback != .none {
                return vm.feedback
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        return .none
    }
}
