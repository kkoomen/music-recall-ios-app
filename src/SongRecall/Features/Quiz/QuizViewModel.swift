import Foundation
import UIKit

/// Owns one quiz session: round presentation, answer handling, timer,
/// scoring, and playback coordination. Main-actor confined.
@MainActor
final class QuizViewModel: ObservableObject {
    enum Feedback: Equatable {
        case none
        case correct(score: Int)
        case wrong
        case skipped
        case timedOut
        case interrupted
    }

    @Published private(set) var roundNumber = 0
    @Published private(set) var totalRounds: Int
    @Published private(set) var score = 0
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var feedback: Feedback = .none
    @Published private(set) var artworkImage: UIImage?
    @Published var guess = ""

    private let engine: QuizEngine
    private let audioPlayer: AudioPlaying
    private let mediaLibrary: MediaLibraryProviding
    private var timerTask: Task<Void, Never>?
    private var hasStarted = false
    private let onFinish: (QuizResult) -> Void

    var currentTrack: Track? { engine.currentRound?.track }
    var canSubmit: Bool {
        feedback == .none
            && !guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var roundIsActive: Bool { feedback == .none }

    init(
        engine: QuizEngine,
        audioPlayer: AudioPlaying,
        mediaLibrary: MediaLibraryProviding,
        onFinish: @escaping (QuizResult) -> Void
    ) {
        self.engine = engine
        self.audioPlayer = audioPlayer
        self.mediaLibrary = mediaLibrary
        self.totalRounds = engine.session.rounds.count
        self.remainingSeconds = Int(engine.configuration.roundDuration)
        self.onFinish = onFinish
        audioPlayer.onPlaybackInterruption = { [weak self] in
            self?.handlePlaybackInterruption()
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        _ = engine.begin()
        beginRound()
    }

    func submit() {
        guard feedback == .none, let outcome = engine.submitAnswer(guess) else { return }
        settle(outcome)
    }

    func skip() {
        guard feedback == .none, let outcome = engine.skip() else { return }
        settle(outcome)
    }

    func advance() {
        guard feedback != .none else { return }
        switch engine.advance() {
        case .playing:
            beginRound()
        case .finished(let result):
            finish(result)
        case .notStarted:
            break
        }
    }

    // MARK: - Round lifecycle

    private func beginRound() {
        guard let round = engine.currentRound else { return }
        if case .playing(let index) = engine.state {
            roundNumber = index + 1
        }
        feedback = .none
        guess = ""
        remainingSeconds = Int(engine.configuration.roundDuration)
        loadArtwork()
        prepareAndPlay(assetURL: round.track.assetURL)
        startTimer()
    }

    private func settle(_ outcome: RoundOutcome) {
        timerTask?.cancel()
        audioPlayer.stop()
        switch outcome {
        case .correct(let elapsed):
            let points = ScoreCalculator.score(forCorrectAnswerAt: elapsed)
            score += points
            feedback = .correct(score: points)
            Haptics.success()
        case .wrong:
            feedback = .wrong
            Haptics.error()
        case .skipped:
            feedback = .skipped
            Haptics.lightImpact()
        case .timedOut:
            feedback = .timedOut
            Haptics.error()
        case .interrupted:
            feedback = .interrupted
            Haptics.error()
        }
    }

    private func finish(_ result: QuizResult) {
        timerTask?.cancel()
        audioPlayer.stop()
        onFinish(result)
    }

    private func handlePlaybackInterruption() {
        guard feedback == .none else { return }
        _ = engine.interrupt()
        settle(.interrupted)
    }

    private func loadArtwork() {
        guard let track = engine.currentRound?.track else {
            artworkImage = nil
            return
        }
        artworkImage = mediaLibrary.artworkData(for: track.id).flatMap(UIImage.init(data:))
    }

    private func prepareAndPlay(assetURL: URL) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.audioPlayer.prepare(assetURL: assetURL)
                // The round may have ended while the asset was loading.
                guard self.feedback == .none else { return }
                self.audioPlayer.playFromStart()
            } catch {
                guard self.feedback == .none else { return }
                _ = self.engine.interrupt()
                self.settle(.interrupted)
            }
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self.tick()
            }
        }
    }

    private func tick() {
        guard let round = engine.currentRound, let startElapsed = round.startElapsed else {
            return
        }
        let elapsed = max(0, engine.now - startElapsed)
        remainingSeconds = max(0, Int(ceil(engine.configuration.roundDuration - elapsed)))
        if let outcome = engine.markTimedOutIfNeeded() {
            settle(outcome)
        }
    }
}
