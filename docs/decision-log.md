# Decision Log

Record decisions that affect architecture, product behavior, privacy, or roadmap order.

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
