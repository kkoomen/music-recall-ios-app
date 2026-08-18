import Foundation

/// Settles an authorization status and a fetched catalog into a
/// user-visible library state. Pure and deterministic.
enum LibraryStateResolver {
    static func state(
        status: MusicAuthorizationStatus,
        tracks: [Track]
    ) -> MusicLibraryState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorized:
            return tracks.isEmpty ? .empty : .ready(tracks)
        }
    }
}
