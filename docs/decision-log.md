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
