import Foundation

/// Errors surfaced by the audio runtime.
enum PlaybackError: Error, Equatable, Sendable {
    /// The asset URL is not playable locally.
    case assetUnavailable
}

/// Injectable boundary around local audio playback.
///
/// Implementations play one prepared local asset from the beginning and
/// stop it on demand. The quiz layer decides when a round ends; the
/// runtime only reports system-driven interruptions.
@MainActor
protocol AudioPlaying: AnyObject {
    /// Called when the system interrupts playback or tears down the
    /// active route (phone call, headphones unplugged, another app
    /// taking over). The runtime stops playback before calling this.
    var onPlaybackInterruption: (() -> Void)? { get set }
    var isPlaying: Bool { get }
    /// Loads the local asset and resets position to zero. Throws
    /// `PlaybackError.assetUnavailable` for missing or unsupported files.
    func prepare(assetURL: URL) async throws
    /// Resets position to zero (again) and starts playing.
    func playFromStart()
    /// Stops playback and releases the current item.
    func stop()
}
