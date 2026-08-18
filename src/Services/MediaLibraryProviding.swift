import Foundation

/// Injectable boundary between the app and the MediaPlayer framework.
///
/// Implementations must not perform network calls and must only expose
/// tracks that are playable from local assets.
@MainActor
protocol MediaLibraryProviding: AnyObject {
    var authorizationStatus: MusicAuthorizationStatus { get }
    func requestAuthorization() async -> MusicAuthorizationStatus
    /// Playable local tracks for the current Music library.
    /// Throws when access is not authorized.
    func fetchTracks() async throws -> [Track]
    /// Lazy artwork data (JPEG) for a track, or nil when unavailable.
    func artworkData(for trackID: Track.ID) -> Data?
}
