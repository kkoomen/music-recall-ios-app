import Foundation
import MediaPlayer

/// MediaPlayer adapter that reads the user's Music library.
///
/// Main-actor isolated because `MPMediaItem` and artwork extraction are
/// not thread-safe. Keeps a lightweight cache of items after a catalog
/// fetch so artwork can be extracted lazily per quiz round.
@MainActor
final class MediaLibraryService: MediaLibraryProviding {
    private var cachedItems: [UInt64: MPMediaItem] = [:]

    init() {}

    var authorizationStatus: MusicAuthorizationStatus {
        switch MPMediaLibrary.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async -> MusicAuthorizationStatus {
        let status = await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
        return status.mapToDomain
    }

    func fetchTracks() async throws -> [Track] {
        guard authorizationStatus == .authorized else {
            throw MediaLibraryError.notAuthorized
        }
        let items = MPMediaQuery.songs().items ?? []
        cachedItems.removeAll(keepingCapacity: true)
        for item in items {
            cachedItems[item.persistentID] = item
        }
        return TrackMapper.makeTracks(from: items.map(record(from:)))
    }

    func artworkData(for trackID: Track.ID) -> Data? {
        guard let item = cachedItems[trackID] else { return nil }
        let size = CGSize(width: 512, height: 512)
        return item.artwork?.image(at: size)?.jpegData(compressionQuality: 0.85)
    }

    private func record(from item: MPMediaItem) -> MediaItemRecord {
        MediaItemRecord(
            id: item.persistentID,
            title: item.title,
            artist: item.artist,
            album: item.albumTitle,
            assetURL: item.assetURL,
            hasProtectedAsset: item.hasProtectedAsset
        )
    }
}

enum MediaLibraryError: Error, Equatable {
    case notAuthorized
}

extension MPMediaLibraryAuthorizationStatus {
    fileprivate var mapToDomain: MusicAuthorizationStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }
}
