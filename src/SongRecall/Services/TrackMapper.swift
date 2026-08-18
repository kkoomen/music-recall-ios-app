import Foundation

/// Maps plain media records to domain tracks, excluding everything that
/// cannot be played locally. Pure and deterministic.
enum TrackMapper {
    static func makeTracks(from records: [MediaItemRecord]) -> [Track] {
        records.compactMap(makeTrack(from:))
    }

    static func makeTrack(from record: MediaItemRecord) -> Track? {
        guard !record.hasProtectedAsset, let assetURL = record.assetURL else {
            return nil
        }
        return Track(
            id: record.id,
            title: record.title ?? "Unknown Title",
            artist: record.artist ?? "Unknown Artist",
            album: record.album ?? "Unknown Album",
            assetURL: assetURL
        )
    }
}
