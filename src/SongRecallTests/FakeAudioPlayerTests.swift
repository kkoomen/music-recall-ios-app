import XCTest
@testable import SongRecall

@MainActor
final class FakeAudioPlayerTests: XCTestCase {
    private let url = URL(string: "ipod-library://item/item.mp3?id=1")!

    func testRecordsPreparePlayStopOrder() async {
        let player = FakeAudioPlayer()
        try? await player.prepare(assetURL: url)
        player.playFromStart()
        player.stop()

        XCTAssertEqual(player.events, [.prepare(url), .play, .stop])
    }

    func testIsPlayingTracksPlaybackLifecycle() async {
        let player = FakeAudioPlayer()
        try? await player.prepare(assetURL: url)
        XCTAssertFalse(player.isPlaying)

        player.playFromStart()
        XCTAssertTrue(player.isPlaying)

        player.stop()
        XCTAssertFalse(player.isPlaying)
    }

    func testPrepareErrorPropagates() async {
        let player = FakeAudioPlayer()
        player.prepareError = .assetUnavailable

        do {
            try await player.prepare(assetURL: url)
            XCTFail("Expected prepare to throw")
        } catch {
            XCTAssertEqual(error as? PlaybackError, .assetUnavailable)
        }
    }

    func testInterruptionStopsPlaybackAndNotifies() async {
        let player = FakeAudioPlayer()
        try? await player.prepare(assetURL: url)
        player.playFromStart()

        var notified = false
        player.onPlaybackInterruption = { notified = true }
        player.simulateInterruption()

        XCTAssertTrue(notified)
        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.events.last, .stop)
    }
}
