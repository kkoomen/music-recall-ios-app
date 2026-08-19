import Foundation

/// Owns one quiz session: round presentation, answer handling, timer,
/// scoring, and playback coordination. Main-actor confined.
@MainActor
final class QuizViewModel: ObservableObject {
    enum Feedback: Equatable {
        case none
        case correct(points: Int, isFast: Bool)
        case wrong(points: Int)
        case skipped(points: Int)
        case timedOut
        case interrupted
    }

    @Published private(set) var roundNumber = 0
    @Published private(set) var totalRounds: Int
    @Published private(set) var score = 0
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var feedback: Feedback = .none
    @Published private(set) var suggestions: [TrackSuggestion] = []
    /// Easy and expert modes: the five multiple-choice options for the
    /// active round.
    @Published private(set) var options: [Track] = []
    /// Easy and expert modes: the option the player picked, kept for
    /// highlighting after the round settles.
    @Published private(set) var selectedOptionID: UInt64?
    /// Expert mode: sample plays remaining this round (3 max), reset
    /// every round.
    @Published private(set) var sampleAttemptsRemaining = 0
    /// Expert mode: true while the 1-second sample is playing.
    @Published private(set) var isSamplePlaying = false
    @Published var guess = ""

    /// Debounce between the last keystroke and suggestion refresh.
    static let suggestionDebounce: Duration = .milliseconds(400)
    /// Expert mode: how often the 1-second sample may be replayed per
    /// round.
    static let maxSampleAttempts = 3

    private let engine: QuizEngine
    private let audioPlayer: AudioPlaying
    private let random: RandomSource
    private let catalog: [Track]
    private let suggestionIndex: [TrackSuggestionRanker.IndexEntry]
    private var timerTask: Task<Void, Never>?
    private var suggestionTask: Task<Void, Never>?
    private var sampleTask: Task<Void, Never>?
    private var sampleOffset: TimeInterval?
    private var hasStarted = false
    private let onFinish: (QuizResult) -> Void

    var currentTrack: Track? { engine.currentRound?.track }
    /// Multiple-choice modes: the track identity that counts as correct
    /// this round.
    var correctOptionID: UInt64? { engine.currentRound?.track.id }
    var isEasyMode: Bool { engine.configuration.mode == .easy }
    var isExpertMode: Bool { engine.configuration.mode == .expert }
    /// Easy and expert share the multiple-choice mechanics.
    var isMultipleChoiceMode: Bool { engine.configuration.mode != .hard }
    var canPlaySample: Bool {
        isExpertMode && roundIsActive && sampleAttemptsRemaining > 0 && !isSamplePlaying
    }
    var canSubmit: Bool {
        feedback == .none
            && !isMultipleChoiceMode
            && !guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var roundIsActive: Bool { feedback == .none }

    init(
        engine: QuizEngine,
        audioPlayer: AudioPlaying,
        catalog: [Track],
        random: RandomSource,
        onFinish: @escaping (QuizResult) -> Void
    ) {
        self.engine = engine
        self.audioPlayer = audioPlayer
        self.random = random
        self.catalog = catalog
        self.suggestionIndex = TrackSuggestionRanker.makeIndex(from: catalog)
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
        guard !isMultipleChoiceMode, feedback == .none, let outcome = engine.submitAnswer(guess) else { return }
        settle(outcome)
    }

    /// Fills the answer field with the suggestion's title and submits it
    /// as the player's answer.
    func select(_ suggestion: TrackSuggestion) {
        guard !isMultipleChoiceMode, feedback == .none else { return }
        guess = suggestion.track.title
        submit()
    }

    /// Multiple-choice modes: picks one of the options. The round
    /// settles immediately; identity (not title text) decides the
    /// outcome.
    func selectOption(_ track: Track) {
        guard isMultipleChoiceMode, feedback == .none else { return }
        selectedOptionID = track.id
        guard let outcome = engine.submitOption(trackID: track.id) else { return }
        settle(outcome)
    }

    /// Sample mode: plays the round's 1-second sample from its random
    /// part. The same part is replayed on every press; at most
    /// `maxSampleAttempts` manual presses per round, then the button
    /// locks.
    func playSample() {
        guard canPlaySample, let track = engine.currentRound?.track else { return }
        sampleAttemptsRemaining -= 1
        playSampleInternal(track: track)
    }

    /// Sample mode: plays the round's first sample automatically at
    /// round start, without consuming a manual play — the player still
    /// has all `maxSampleAttempts` presses.
    private func playSampleAutomatically() {
        guard isExpertMode, feedback == .none, let track = engine.currentRound?.track else { return }
        isSamplePlaying = true
        playSampleInternal(track: track)
    }

    /// Loads the duration on the first play of the round, picks the
    /// random offset once, plays the 1-second sample from it, and stops
    /// it one second later. Failures settle the round as interrupted.
    private func playSampleInternal(track: Track) {
        isSamplePlaying = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if self.sampleOffset == nil {
                    let duration = try await self.audioPlayer.loadDuration(of: track.assetURL)
                    self.sampleOffset = SamplePicker.offset(
                        songDuration: duration,
                        random: self.random
                    )
                }
                try await self.audioPlayer.playSample(
                    assetURL: track.assetURL,
                    at: self.sampleOffset ?? 0
                )
                // The round may have settled while the sample was loading.
                guard self.feedback == .none else { return }
                self.startSampleStopTimer()
            } catch {
                guard self.feedback == .none else { return }
                self.isSamplePlaying = false
                _ = self.engine.interrupt()
                self.settle(.interrupted)
            }
        }
    }

    /// Debounced search entry point, called whenever the guess changes.
    /// Suggestions refresh 400ms after the last keystroke. Clearing the
    /// input keeps the last results so the dropdown stays open for
    /// enter-to-select-first.
    func guessDidChange() {
        suggestionTask?.cancel()
        guard !AnswerNormalizer.normalize(guess).isEmpty else { return }
        suggestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.suggestionDebounce)
            guard !Task.isCancelled else { return }
            self?.refreshSuggestions()
        }
    }

    /// Keyboard return handling: with a value in the field, submit it.
    /// With an empty field and the dropdown open, select the first
    /// suggestion. With an empty field and no dropdown, do nothing so
    /// pressing return can never cause an accidental wrong answer.
    func submitFromKeyboard() {
        let trimmed = guess.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if let first = suggestions.first {
                select(first)
            }
        } else {
            submit()
        }
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

    private func refreshSuggestions() {
        guard feedback == .none else { return }
        suggestions = TrackSuggestionRanker.rank(
            query: guess,
            index: suggestionIndex,
            random: random
        )
    }

    private func beginRound() {
        guard let round = engine.currentRound else { return }
        if case .playing(let index) = engine.state {
            roundNumber = index + 1
        }
        feedback = .none
        guess = ""
        selectedOptionID = nil
        sampleOffset = nil
        sampleTask?.cancel()
        isSamplePlaying = false
        sampleAttemptsRemaining = isExpertMode ? Self.maxSampleAttempts : 0
        if isMultipleChoiceMode {
            options = OptionGenerator.options(for: round.track, from: catalog, random: random)
        } else {
            options = []
        }
        remainingSeconds = Int(engine.configuration.roundDuration)
        if isExpertMode {
            // Sample mode: the first 1-second sample plays automatically
            // (free of charge) and the button replays the same part.
            playSampleAutomatically()
        } else {
            prepareAndPlay(assetURL: round.track.assetURL)
        }
        startTimer()
    }

    private func settle(_ outcome: RoundOutcome) {
        timerTask?.cancel()
        suggestionTask?.cancel()
        sampleTask?.cancel()
        sampleOffset = nil
        isSamplePlaying = false
        suggestions = []
        audioPlayer.stop()
        switch outcome {
        case .correct(let elapsed):
            let breakdown = ScoreCalculator.breakdown(
                forCorrectAnswerAt: elapsed,
                roundDuration: engine.configuration.roundDuration,
                fastThreshold: engine.configuration.fastThreshold
            )
            score += breakdown.points
            feedback = .correct(points: breakdown.points, isFast: breakdown.isFast)
            Haptics.success()
        case .wrong:
            score = max(0, score - ScoreCalculator.wrongPenalty)
            feedback = .wrong(points: -ScoreCalculator.wrongPenalty)
            Haptics.error()
        case .skipped:
            score = max(0, score - ScoreCalculator.skipPenalty)
            feedback = .skipped(points: -ScoreCalculator.skipPenalty)
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
        sampleTask?.cancel()
        audioPlayer.stop()
        onFinish(result)
    }

    private func handlePlaybackInterruption() {
        guard feedback == .none else { return }
        _ = engine.interrupt()
        settle(.interrupted)
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

    /// Stops the 1-second sample one second after it started playing.
    private func startSampleStopTimer() {
        sampleTask?.cancel()
        sampleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(SamplePicker.sampleDuration))
            guard !Task.isCancelled else { return }
            guard let self, self.isSamplePlaying else { return }
            self.isSamplePlaying = false
            self.audioPlayer.stop()
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
