import XCTest
@testable import SongRecall

final class TrackMapperTests: XCTestCase {
    private func record(
        id: UInt64 = 1,
        title: String? = "Title",
        artist: String? = "Artist",
        album: String? = "Album",
        assetURL: URL? = URL(string: "ipod-library://item/item.mp3?id=1")!,
        hasProtectedAsset: Bool = false
    ) -> MediaItemRecord {
        MediaItemRecord(
            id: id,
            title: title,
            artist: artist,
            album: album,
            assetURL: assetURL,
            hasProtectedAsset: hasProtectedAsset
        )
    }

    func testMapsAllFields() throws {
        let url = URL(string: "ipod-library://item/item.mp3?id=42")!
        let track = try XCTUnwrap(TrackMapper.makeTrack(
            from: record(id: 42, title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", assetURL: url)
        ))
        XCTAssertEqual(track.id, 42)
        XCTAssertEqual(track.title, "Bohemian Rhapsody")
        XCTAssertEqual(track.artist, "Queen")
        XCTAssertEqual(track.album, "A Night at the Opera")
        XCTAssertEqual(track.assetURL, url)
    }

    func testExcludesRecordWithoutAssetURL() {
        let track = TrackMapper.makeTrack(from: record(assetURL: nil))
        XCTAssertNil(track)
    }

    func testExcludesProtectedAssetEvenWithAssetURL() {
        let track = TrackMapper.makeTrack(from: record(hasProtectedAsset: true))
        XCTAssertNil(track)
    }

    func testFallsBackForMissingMetadata() throws {
        let track = try XCTUnwrap(TrackMapper.makeTrack(
            from: record(title: nil, artist: nil, album: nil)
        ))
        XCTAssertEqual(track.title, "Unknown Title")
        XCTAssertEqual(track.artist, "Unknown Artist")
        XCTAssertEqual(track.album, "Unknown Album")
    }

    func testKeepsStableIdentityForDuplicateTitles() {
        let a = TrackMapper.makeTrack(from: record(id: 7, title: "Same Title"))
        let b = TrackMapper.makeTrack(from: record(id: 8, title: "Same Title"))
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertNotEqual(a?.id, b?.id)
    }

    func testFilteringKeepsOnlyPlayableRecords() {
        let records = [
            record(id: 1, assetURL: URL(string: "ipod-library://item/a.mp3")!),
            record(id: 2, assetURL: nil),
            record(id: 3, hasProtectedAsset: true),
            record(id: 4, assetURL: URL(string: "ipod-library://item/b.mp3")!),
        ]
        let tracks = TrackMapper.makeTracks(from: records)
        XCTAssertEqual(tracks.map(\.id), [1, 4])
    }
}
