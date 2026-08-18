import Foundation
@testable import SongRecall

/// Recording test double for `AudioPlaying`. Never touches AVFoundation.
@MainActor
final class FakeAudioPlayer: AudioPlaying {
    enum Event: Equatable, Sendable {
        case prepare(URL)
        case play
        case stop
    }

    var onPlaybackInterruption: (() -> Void)?
    var prepareError: PlaybackError?

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

    func stop() {
        events.append(.stop)
        isPlaying = false
    }

    func simulateInterruption() {
        stop()
        onPlaybackInterruption?()
    }
}
