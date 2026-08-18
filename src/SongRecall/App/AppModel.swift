import Foundation

/// Composition root state: owns services, library state, and navigation.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var libraryState: MusicLibraryState = .loading
    @Published private(set) var route: AppRoute = .library

    private let mediaLibrary: MediaLibraryProviding
    private let audioPlayer: AudioPlaying
    private let clock: Clocking
    private let random: RandomSource
    private let roundDurationOverride: TimeInterval?

    private(set) var quizViewModel: QuizViewModel?

    init(
        mediaLibrary: MediaLibraryProviding,
        audioPlayer: AudioPlaying,
        clock: Clocking,
        random: RandomSource,
        roundDurationOverride: TimeInterval? = nil
    ) {
        self.mediaLibrary = mediaLibrary
        self.audioPlayer = audioPlayer
        self.clock = clock
        self.random = random
        self.roundDurationOverride = roundDurationOverride
    }

    /// Builds the production app model, or a UI-test stub model when
    /// `-uitest-library` is present in the launch arguments.
    static func makeFromEnvironment() -> AppModel {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-uitest-library"),
           arguments.indices.contains(index + 1),
           let mode = StubMediaLibrary.Mode(rawValue: arguments[index + 1])
        {
            return AppModel(
                mediaLibrary: StubMediaLibrary(mode: mode),
                audioPlayer: StubAudioPlayer(),
                clock: SystemClock(),
                random: SeededRandomSource(seed: 0),
                roundDurationOverride: uitestRoundDuration()
            )
        }
        return AppModel(
            mediaLibrary: MediaLibraryService(),
            audioPlayer: AVPlayerAudioPlayer(),
            clock: SystemClock(),
            random: SystemRandomSource()
        )
    }

    /// Reads an optional `-uitest-round-duration` launch argument so UI
    /// tests can exercise timeout without waiting 30 real seconds.
    private static func uitestRoundDuration() -> TimeInterval? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-uitest-round-duration"),
              arguments.indices.contains(index + 1),
              let duration = TimeInterval(arguments[index + 1]),
              duration > 0
        else { return nil }
        return duration
    }

    func loadLibrary() async {
        switch mediaLibrary.authorizationStatus {
        case .authorized:
            libraryState = .loading
            do {
                let tracks = try await mediaLibrary.fetchTracks()
                libraryState = LibraryStateResolver.state(status: .authorized, tracks: tracks)
            } catch {
                libraryState = .empty
            }
        case .notDetermined, .denied, .restricted:
            libraryState = LibraryStateResolver.state(
                status: mediaLibrary.authorizationStatus,
                tracks: []
            )
        }
    }

    func requestAccessAndLoad() async {
        let status = await mediaLibrary.requestAuthorization()
        libraryState = .loading
        if status == .authorized {
            do {
                let tracks = try await mediaLibrary.fetchTracks()
                libraryState = LibraryStateResolver.state(status: .authorized, tracks: tracks)
            } catch {
                libraryState = .empty
            }
        } else {
            libraryState = LibraryStateResolver.state(status: status, tracks: [])
        }
    }

    func startQuiz() {
        guard case .ready(let tracks) = libraryState, !tracks.isEmpty else { return }
        let configuration: QuizConfiguration
        if let roundDurationOverride {
            configuration = QuizConfiguration(roundCount: 10, roundDuration: roundDurationOverride)
        } else {
            configuration = .default
        }
        let engine = QuizEngine(catalog: tracks, configuration: configuration, random: random, clock: clock)
        let viewModel = QuizViewModel(
            engine: engine,
            audioPlayer: audioPlayer,
            catalog: tracks
        ) { [weak self] result in
            self?.finishQuiz(result)
        }
        quizViewModel = viewModel
        route = .quiz
    }

    func finishQuiz(_ result: QuizResult) {
        route = .results(result)
    }

    func replay() {
        startQuiz()
    }

    func backToLibrary() {
        route = .library
        quizViewModel = nil
        Task { await loadLibrary() }
    }
}
