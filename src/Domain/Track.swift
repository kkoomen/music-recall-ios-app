import Foundation

/// A locally playable song from the user's Music library.
///
/// Pure value type: no MediaPlayer, AVFoundation, or SwiftUI types.
/// Artwork is fetched lazily through the media library service so the
/// catalog stays light even for large libraries.
struct Track: Identifiable, Equatable, Hashable, Sendable {
    /// Stable identity backed by MediaPlayer's persistent media identifier.
    /// Duplicate titles are still distinct tracks.
    let id: UInt64
    let title: String
    let artist: String
    let album: String
    /// Local asset URL used for playback. Non-nil means the track is
    /// playable from this device.
    let assetURL: URL
}
