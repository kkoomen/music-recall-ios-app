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

    func stop() {
        isPlaying = false
    }
}
