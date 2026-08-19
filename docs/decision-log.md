# Decision Log

Record decisions that affect architecture, product behavior, privacy, or roadmap order.

## 2026-08-19: Home mode names swapped; sample auto-plays at round start

Decision: The home screen now labels the 1-second-sample quiz "Hard Mode" and the typed-answer quiz "Expert Mode" (internal `QuizMode` cases unchanged). In the sample quiz, the first 1-second sample plays automatically when each round starts and does not consume a play — the player still has three manual plays.

Reason: User request; the sample mode is the harder challenge and should open with an immediate listen.

Consequence: HomeView labels swapped (`home.startExpert` starts the sample quiz, `home.startHard` the typed quiz — identifiers unchanged). `QuizViewModel` picks the round's random offset during the automatic first play and replays the same part on manual presses; `sampleAttemptsRemaining` still starts at 3. ROADMAP sections 6, 10, and 11, docs/quiz-rules.md, and docs/design-system.md updated.

## 2026-08-19: Expert mode with limited 1-second sample playback

Decision: Added a third home-screen mode, Expert, identical to easy mode except the song never auto-plays; a Play Sample button replays a 1-second sample of one random part per round, at most three times, resetting each round.

Reason: User request for a harder listen-based variant of the multiple-choice quiz.

Consequence: `QuizMode.expert` shares easy's mechanics and 3-second fast window; `AudioPlaying` gained `loadDuration(of:)` and `playSample(assetURL:at:)`; `RandomSource` gained `nextDouble()`; `SamplePicker` picks the per-round offset so every press replays the same part. Device validation of sample seek/playback stays blocked (no signed device build). ROADMAP section 11, docs/quiz-rules.md, and docs/design-system.md updated.

## 2026-08-19: Easy and hard quiz modes

Decision: The home screen now offers two modes — Easy (five multiple-choice options per round) and Hard (the original typed-answer quiz). The 2x fast-answer window is mode-dependent: 3 seconds for easy (27 or more seconds remaining), 5 seconds for hard.

Reason: User request; multiple-choice was previously listed as future work.

Consequence: `QuizMode` and `QuizConfiguration.mode` drive a computed `fastThreshold`; `QuizSession.submitOption` matches picks by track identity (never title text, so a same-title decoy can never count as correct); `OptionGenerator` builds up to five deduplicated, shuffled options; `ScoreCalculator` takes an explicit `fastThreshold` (defaults keep hard-mode behavior); `QuizResult` carries the threshold so totals match the mode. Wrong easy picks highlight both the correct option (success) and the picked option (danger); replay keeps the mode. Home identifiers `home.startEasy`/`home.startHard` replace `home.startQuiz`; `quiz.option` added. docs/quiz-rules.md, docs/design-system.md, and ROADMAP section 10 reflect the new behavior.

## 2026-08-18: Media source

Decision: Use Apple Music library through MediaPlayer for MVP.

Reason: User requested local phone music without Spotify or external APIs.

Consequence: Arbitrary MP3s in Files.app are out of scope. Tracks need local playable asset URLs.

## 2026-08-18: Platform

Decision: iOS 26+ and SwiftUI.

Reason: New project targets current Apple platform APIs and avoids compatibility branches.

## 2026-08-18: Quiz rules

Decision: Ten random rounds, thirty seconds each, free-text answer, linear score decay.

Reason: Minimal first loop with clear speed incentive.

## 2026-08-18: MVP release readiness verified on simulator

Decision: Release configuration, privacy, and messaging gates verified on the simulator; device-only checks stay blocked.

Evidence: Release simulator build succeeds; built Info.plist contains the Apple Music usage description; no network imports (URLSession/Network), no Swift packages, and no entitlements in the signed app; permission-denied, restricted, empty, and playback-failure states have defined UI (covered by unit and UI tests).

Consequence: docs/release-checklist.md marks all simulator-verifiable items complete. Before shipping to a real iPhone, run the device-only follow-ups listed there.

## 2026-08-18: Scoring formula updated

Decision: Replaced the linear max(100, 1000 - floor(elapsed) x 30) formula with (10 + remaining seconds) x multiplier, plus penalties for wrong answers and skips.

Reason: User redesign; large point values felt arbitrary and the penalty was opaque.

Consequence: Correct answers earn 10 base points plus one point per remaining second (displayed countdown), doubled when answered within the first 5 seconds (with a "You're fast! 2x multiplier" celebration). Wrong answers deduct 5, skips deduct 10, timeout and interruption score 0, and the running and total scores clamp at 0. docs/quiz-rules.md and ROADMAP section 5 reflect the new formula.

## 2026-08-18: Fast-answer multiplier window widened to 25 seconds

Decision: The 2x multiplier now applies to correct answers at or before 25 seconds (previously strictly before 5 seconds).

Reason: User feedback; the 5-second window almost never triggered in practice, so the celebration never appeared.

Consequence: Nearly every correct answer inside the 30-second round now shows the "You're fast! 2x multiplier" celebration; only answers in the final 5 seconds (after 25s) score without the multiplier. Boundary tests and docs updated.

## 2026-08-18: Fast-answer multiplier window reverted to 5 seconds

Decision: The 2x multiplier applies only to correct answers at or before 5 seconds (25 or more seconds remaining on the clock).

Reason: The 25-second window made the multiplier show on every correct answer, which diluted the celebration; the user wants it to be a genuine speed bonus.

Consequence: "You're fast! 2x multiplier" shows only for answers in the first 5 seconds; everything after that scores without the multiplier. Boundary tests and docs updated.

## Update rule

Add dated entries when a decision changes. Link the affected ROADMAP section. Do not silently rewrite history.

## 2026-08-18: Source layout aligned with zihe

Decision: `src/` mirrors the sibling `zihe` project layout: `src/SongRecall/` (app source), `src/SongRecall.xcodeproj`, `src/SongRecallTests/`, `src/SongRecallUITests/`.

Reason: Consistent structure across the user's projects; the repo-root `tests/` folder was replaced by the per-target test folders next to the project.

Consequence: `AGENTS.md`, `src/STRUCTURE.md`, and `docs/build-and-run.md` now document the new paths. Synchronized groups reference `SongRecall/`, `SongRecallTests/`, and `SongRecallUITests/`.

## 2026-08-18: Device-only checks blocked

Decision: Physical-device media-library and audio checks cannot run in this environment (no signed iPhone build executed).

Reason: Simulator cannot represent a personal Music library and no device build/signing session was run.

Consequence: ROADMAP items that require a real iPhone (media-library authorization flow, local audio playback, interruption handling) stay recorded as blocked until a device session runs. All other gates are verified on the simulator.
