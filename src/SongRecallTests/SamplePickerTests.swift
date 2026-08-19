import XCTest
@testable import SongRecall

final class SamplePickerTests: XCTestCase {
    func testLongSongProducesOffsetWithinSampleRange() {
        let offset = SamplePicker.offset(
            songDuration: 60,
            random: SeededRandomSource(seed: 7)
        )
        XCTAssertGreaterThanOrEqual(offset, 0)
        XCTAssertLessThanOrEqual(offset, 60 - SamplePicker.sampleDuration)
    }

    func testOffsetIsDeterministicPerSeed() {
        XCTAssertEqual(
            SamplePicker.offset(songDuration: 90, random: SeededRandomSource(seed: 42)),
            SamplePicker.offset(songDuration: 90, random: SeededRandomSource(seed: 42))
        )
    }

    func testDifferentSeedsCanProduceDifferentOffsets() {
        let a = SamplePicker.offset(songDuration: 120, random: SeededRandomSource(seed: 1))
        let b = SamplePicker.offset(songDuration: 120, random: SeededRandomSource(seed: 2))
        XCTAssertNotEqual(a, b)
    }

    func testSongExactlySampleLengthStartsAtZero() {
        XCTAssertEqual(
            SamplePicker.offset(
                songDuration: SamplePicker.sampleDuration,
                random: SeededRandomSource(seed: 0)
            ),
            0
        )
    }

    func testSongShorterThanSampleStartsAtZero() {
        XCTAssertEqual(
            SamplePicker.offset(songDuration: 0.4, random: SeededRandomSource(seed: 0)),
            0
        )
    }

    func testZeroAndNegativeDurationsClampToZero() {
        XCTAssertEqual(SamplePicker.offset(songDuration: 0, random: SeededRandomSource(seed: 0)), 0)
        XCTAssertEqual(SamplePicker.offset(songDuration: -5, random: SeededRandomSource(seed: 0)), 0)
    }
}
