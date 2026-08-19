import XCTest

/// Easy-mode journey: five (here: three, stub catalog) options instead
/// of the text input, one pick per round, and correct/wrong highlights
/// after settling.
///
/// Stub library selection order (seed 0): Gamma Song, Beta Song,
/// Alpha Song. The stub catalog has three tracks, so easy mode shows
/// three options.
final class EasyModeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
    }

    func testEasyModeJourneyToResults() throws {
        app.launch()

        let easyButton = app.buttons["home.startEasy"]
        XCTAssertTrue(easyButton.waitForExistence(timeout: 5))
        easyButton.tap()

        // Round 1: pick the correct option (Gamma Song).
        assertRound(number: 1, of: 3)
        option("Gamma Song, Artist Three").tap()
        // Picked within 3 seconds: the easy-mode 2x celebration shows.
        assertFeedback(contains: "2x")
        // The picked correct option is highlighted as the answer.
        XCTAssertEqual(
            option("Gamma Song, Artist Three").value as? String,
            "Correct answer",
            "The correct option must be highlighted after settling"
        )
        app.buttons["quiz.next"].tap()

        // Round 2: pick a wrong option (Alpha Song) for Beta Song.
        assertRound(number: 2, of: 3)
        option("Alpha Song, Artist One").tap()
        assertFeedback(contains: "Not this time")
        // Both the correct and the picked-wrong options are highlighted.
        XCTAssertEqual(
            option("Beta Song, Artist Two").value as? String,
            "Correct answer",
            "The correct option must be highlighted on a wrong pick"
        )
        XCTAssertEqual(
            option("Alpha Song, Artist One").value as? String,
            "Your answer",
            "The picked wrong option must be highlighted"
        )
        // The reveal still names the song.
        let reveal = app.descendants(matching: .any)
            .matching(identifier: "quiz.reveal")
            .firstMatch
        XCTAssertTrue(reveal.waitForExistence(timeout: 5))
        XCTAssertEqual(reveal.label, "The song was Beta Song, Artist Two")
        app.buttons["quiz.next"].tap()

        // Round 3: skip (Alpha Song).
        assertRound(number: 3, of: 3)
        app.buttons["quiz.skip"].tap()
        assertFeedback(contains: "Skipped")
        app.buttons["quiz.next"].tap()

        // Results. Points depend on tap timing, so assert the
        // deterministic stats: exactly one correct round of three.
        let score = app.staticTexts["results.score"]
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        XCTAssertTrue(score.label.hasPrefix("Total score"), "Got: \(score.label)")
        let correct = app.staticTexts["results.correct"]
        XCTAssertTrue(correct.exists)
        XCTAssertEqual(correct.label, "Correct: 1", "Got: \(correct.label)")

        // Exactly one fast pick (round 1) earned the 2x multiplier.
        let multipliers = app.staticTexts["results.multipliers"]
        XCTAssertTrue(multipliers.exists)
        XCTAssertEqual(multipliers.label, "2x Multipliers: 1", "Got: \(multipliers.label)")

        // Replay returns to easy mode with a fresh round.
        app.buttons["results.replay"].tap()
        assertRound(number: 1, of: 3)
        XCTAssertFalse(
            app.textFields["quiz.answerField"].exists,
            "Replay must stay in easy mode (no answer field)"
        )
    }

    // MARK: - Helpers

    private func option(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func assertRound(number: Int, of total: Int) {
        let round = app.staticTexts["quiz.round"]
        XCTAssertTrue(round.waitForExistence(timeout: 5))
        let acceptable = ["Round \(number) / \(total)", "Round \(number) of \(total)"]
        XCTAssertTrue(acceptable.contains(round.label), "Expected round \(number) of \(total), got \(round.label)")
        XCTAssertTrue(app.staticTexts["quiz.timer"].exists)
        XCTAssertTrue(app.staticTexts["quiz.score"].exists)
    }

    private func assertFeedback(contains text: String) {
        let feedback = app.descendants(matching: .any)
            .matching(identifier: "quiz.feedback")
            .firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains(text), "Expected feedback containing \(text), got \(feedback.label)")
    }
}
