import Foundation

/// Minimal `AudioPlaying` double for UI-test stub mode and previews.
/// Never touches AVFoundation.
@MainActor
final class StubAudioPlayer: AudioPlaying {
    var onPlaybackInterruption: (() -> Void)?
    private(set) var isPlaying = false

    func prepare(assetURL: URL) async throws {}

    func playFromStart() {
        isPlaying = true
    }

    func loadDuration(of assetURL: URL) async throws -> TimeInterval {
        // Stub songs are treated as 30 seconds long.
        30
    }

    func playSample(assetURL: URL, at offset: TimeInterval) async throws {
        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }
}
