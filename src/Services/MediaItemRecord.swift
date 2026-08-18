import Foundation

/// Plain, testable projection of an `MPMediaItem`.
///
/// The MediaPlayer adapter converts `MPMediaItem` into this record at the
/// framework boundary. All filtering and mapping logic operates on the
/// record so unit tests never need a real Music library.
struct MediaItemRecord: Equatable, Sendable {
    let id: UInt64
    let title: String?
    let artist: String?
    let album: String?
    /// Local asset URL; nil for cloud-only, missing, or unsupported assets.
    let assetURL: URL?
    /// True for DRM-protected items that cannot be decoded locally.
    let hasProtectedAsset: Bool
}
