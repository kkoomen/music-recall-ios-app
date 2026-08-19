import XCTest

/// Expert-mode journey: multiple-choice options like easy mode, but the
/// song is only heard as a 1-second sample — played automatically and
/// free of charge at round start, then replayable via the Play Sample
/// button up to three more times per round (reset each round, grays out
/// once spent).
///
/// Stub library selection order (seed 0): Gamma Song, Beta Song,
/// Alpha Song.
final class ExpertModeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uitest-library", "ready"]
    }

    func testExpertModeJourneyWithLimitedSamplePlays() throws {
        app.launch()

        let expertButton = app.buttons["home.startExpert"]
        XCTAssertTrue(expertButton.waitForExistence(timeout: 5))
        expertButton.tap()

        // Round 1: options are present (no answer field), sample starts
        // with three plays.
        assertRound(number: 1, of: 3)
        XCTAssertFalse(app.textFields["quiz.answerField"].exists)
        XCTAssertTrue(option("Gamma Song, Artist Three").exists)

        let playSample = app.buttons["quiz.playSample"]
        XCTAssertTrue(playSample.waitForExistence(timeout: 5))
        XCTAssertEqual(playSample.label, "Play Sample, 3 plays left")

        // The round opens with a free automatic sample; wait for it to
        // finish so the manual presses count.
        waitUntilEnabled(playSample)

        // Three plays exhaust the attempts; the button grays out.
        playOnce(playSample, expecting: "2 plays left", reenables: true)
        playOnce(playSample, expecting: "1 play left", reenables: true)
        // The last press locks the button, so it never re-enables.
        playOnce(playSample, expecting: "0 plays left", reenables: false)
        XCTAssertFalse(playSample.isEnabled, "Play Sample must lock after three attempts")

        // Pick the correct option; the round settles like easy mode.
        option("Gamma Song, Artist Three").tap()
        assertFeedback(contains: "points")
        XCTAssertTrue(revealElement.waitForExistence(timeout: 5))
        app.buttons["quiz.next"].tap()

        // Round 2: attempts reset to three; the free automatic sample
        // plays again.
        assertRound(number: 2, of: 3)
        XCTAssertEqual(playSample.label, "Play Sample, 3 plays left")
        waitUntilEnabled(playSample)
        playOnce(playSample, expecting: "2 plays left", reenables: true)

        // Wrong pick: both the correct and the picked option highlight.
        option("Alpha Song, Artist One").tap()
        assertFeedback(contains: "Not this time")
        XCTAssertEqual(option("Beta Song, Artist Two").value as? String, "Correct answer")
        XCTAssertEqual(option("Alpha Song, Artist One").value as? String, "Your answer")
        app.buttons["quiz.next"].tap()

        // Round 3: skip.
        assertRound(number: 3, of: 3)
        app.buttons["quiz.skip"].tap()
        assertFeedback(contains: "Skipped")
        app.buttons["quiz.next"].tap()

        // Results: exactly one correct round.
        let score = app.staticTexts["results.score"]
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        let correct = app.staticTexts["results.correct"]
        XCTAssertTrue(correct.exists)
        XCTAssertEqual(correct.label, "Correct: 1", "Got: \(correct.label)")
    }

    // MARK: - Helpers

    /// Waits for the automatic sample (free of charge) to finish so the
    /// next manual press is actually consumed.
    private func waitUntilEnabled(_ button: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Play Sample never re-enabled"
        )
    }

    /// Taps Play Sample and waits until the button shows the expected
    /// remaining-plays label. For the final play the button stays locked
    /// (no re-enable), so `reenables` distinguishes the two cases.
    private func playOnce(_ button: XCUIElement, expecting labelSuffix: String, reenables: Bool) {
        button.tap()
        let predicate = reenables
            ? NSPredicate(format: "isEnabled == true AND label CONTAINS %@", labelSuffix)
            : NSPredicate(format: "label CONTAINS %@", labelSuffix)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: button)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Sample play to '\(labelSuffix)' was not registered"
        )
    }

    private func option(_ label: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private var revealElement: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "quiz.reveal")
            .firstMatch
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
