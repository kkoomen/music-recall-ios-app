import Foundation
@testable import SongRecall

/// Recording test double for `AudioPlaying`. Never touches AVFoundation.
@MainActor
final class FakeAudioPlayer: AudioPlaying {
    enum Event: Equatable, Sendable {
        case prepare(URL)
        case play
        case loadDuration(URL)
        case stop
    }

    var onPlaybackInterruption: (() -> Void)?
    var prepareError: PlaybackError?
    /// Duration reported by `loadDuration` (defaults to 30 seconds).
    var duration: TimeInterval = 30

    private(set) var events: [Event] = []
    private(set) var isPlaying = false

    func prepare(assetURL: URL) async throws {
        events.append(.prepare(assetURL))
        if let prepareError {
            throw prepareError
        }
    }

    func playFromStart() {
        events.append(.play)
        isPlaying = true
    }

    func loadDuration(of assetURL: URL) async throws -> TimeInterval {
        events.append(.loadDuration(assetURL))
        return duration
    }

    func playSample(assetURL: URL, at offset: TimeInterval) async throws {
        events.append(.prepare(assetURL))
        events.append(.play)
        if let prepareError {
            throw prepareError
        }
        isPlaying = true
    }

    func stop() {
        events.append(.stop)
        isPlaying = false
    }

    func simulateInterruption() {
        stop()
        onPlaybackInterruption?()
    }
}
