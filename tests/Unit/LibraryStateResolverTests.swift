import XCTest
@testable import SongRecall

final class LibraryStateResolverTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!
    private var track: Track {
        Track(id: 1, title: "Title", artist: "Artist", album: "Album", assetURL: url)
    }

    func testNotDetermined() {
        XCTAssertEqual(
            LibraryStateResolver.state(status: .notDetermined, tracks: [track]),
            .notDetermined
        )
    }

    func testDenied() {
        XCTAssertEqual(
            LibraryStateResolver.state(status: .denied, tracks: [track]),
            .denied
        )
    }

    func testRestricted() {
        XCTAssertEqual(
            LibraryStateResolver.state(status: .restricted, tracks: [track]),
            .restricted
        )
    }

    func testAuthorizedWithTracksIsReady() {
        XCTAssertEqual(
            LibraryStateResolver.state(status: .authorized, tracks: [track]),
            .ready([track])
        )
    }

    func testAuthorizedWithoutTracksIsEmpty() {
        XCTAssertEqual(
            LibraryStateResolver.state(status: .authorized, tracks: []),
            .empty
        )
    }
}
