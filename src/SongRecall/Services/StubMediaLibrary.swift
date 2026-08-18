import Foundation

/// Fake media library used by UI tests (via launch arguments) and
/// SwiftUI previews. Never touches MediaPlayer or the real Music
/// library, so simulator tests stay deterministic.
///
/// Launch modes: `-uitest-library ready|empty|denied|restricted|notDetermined`.
/// In `ready` mode selection uses `SeededRandomSource(seed: 0)` so UI
/// tests can predict the first round.
@MainActor
final class StubMediaLibrary: MediaLibraryProviding {
    enum Mode: String {
        case ready
        case empty
        case denied
        case restricted
        case notDetermined
    }

    static let tracks: [Track] = [
        Track(
            id: 1,
            title: "Alpha Song",
            artist: "Artist One",
            album: "Stub Album",
            assetURL: URL(string: "stub://track/1")!
        ),
        Track(
            id: 2,
            title: "Beta Song",
            artist: "Artist Two",
            album: "Stub Album",
            assetURL: URL(string: "stub://track/2")!
        ),
        Track(
            id: 3,
            title: "Gamma Song",
            artist: "Artist Three",
            album: "Stub Album",
            assetURL: URL(string: "stub://track/3")!
        ),
    ]

    let mode: Mode
    private(set) var authorizationRequestCount = 0

    init(mode: Mode) {
        self.mode = mode
    }

    var authorizationStatus: MusicAuthorizationStatus {
        switch mode {
        case .ready, .empty: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        }
    }

    func requestAuthorization() async -> MusicAuthorizationStatus {
        authorizationRequestCount += 1
        return authorizationStatus
    }

    func fetchTracks() async throws -> [Track] {
        guard authorizationStatus == .authorized else {
            throw MediaLibraryError.notAuthorized
        }
        return mode == .ready ? Self.tracks : []
    }

    func artworkData(for trackID: Track.ID) -> Data? {
        nil
    }
}
