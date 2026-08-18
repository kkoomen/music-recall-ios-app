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
