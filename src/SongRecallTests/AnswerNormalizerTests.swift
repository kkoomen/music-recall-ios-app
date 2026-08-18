import XCTest
@testable import SongRecall

final class AnswerNormalizerTests: XCTestCase {
    func testLowercasesAndTrims() {
        XCTAssertEqual(AnswerNormalizer.normalize("  BoHEMian  Rhapsody  "), "bohemian rhapsody")
    }

    func testRemovesPunctuation() {
        XCTAssertEqual(AnswerNormalizer.normalize("Don't Stop Me Now!"), "dont stop me now")
        XCTAssertEqual(AnswerNormalizer.normalize("Hello, It's Me (1999)"), "hello its me 1999")
    }

    func testCollapsesWhitespace() {
        XCTAssertEqual(AnswerNormalizer.normalize("a   b\t\tc\n d"), "a b c d")
    }

    func testStripsDiacritics() {
        XCTAssertEqual(AnswerNormalizer.normalize("Café au Lait"), "cafe au lait")
        XCTAssertEqual(AnswerNormalizer.normalize("Séance"), "seance")
    }

    func testKeepsNumbers() {
        XCTAssertEqual(AnswerNormalizer.normalize("Uptown Funk 2014"), "uptown funk 2014")
    }

    func testEmptyInputStaysEmpty() {
        XCTAssertEqual(AnswerNormalizer.normalize(""), "")
        XCTAssertEqual(AnswerNormalizer.normalize("   !!!   "), "")
    }
}
