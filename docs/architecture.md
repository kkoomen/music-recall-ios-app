# Architecture

## Direction

Use feature-oriented SwiftUI with a small pure domain layer. Dependencies point inward:

1. Views display feature state.
2. Feature view models coordinate user actions.
3. Domain types and rules contain quiz behavior.
4. Services adapt Apple frameworks.

Domain must not import SwiftUI, MediaPlayer, or AVFoundation.

## Planned ownership

- src/App: dependency composition and app lifecycle.
- src/Domain: Track, QuizRound, QuizSession, state transitions, answer matching, scoring.
- src/Services: MediaPlayer adapter, AVFoundation adapter, clock, random source.
- src/Features/Home: library status and start action.
- src/Features/Permission: authorization, denial, restricted, and empty states.
- src/Features/Quiz: active round presentation and answer actions.
- src/Features/Results: session summary and replay.
- src/DesignSystem: tokens and reusable visual components.
- src/Resources: app-owned local assets and configuration.

## State rules

- Feature view models own mutable screen state.
- Shared state crosses features through explicit models or dependency protocols.
- Time, randomness, media access, and playback are injectable.
- UI never queries MediaPlayer or AVFoundation directly.
- Terminal quiz states reject later answer events.

## Concurrency

Use Swift structured concurrency and strict concurrency checking. UI-facing state belongs on the main actor. Keep framework adapters isolated where needed. Avoid detached work unless ownership and cancellation are explicit.

## Error handling

Represent expected errors as user-visible states:

- permission denied;
- restricted access;
- empty local library;
- unavailable asset;
- playback failure;
- interrupted playback.

Do not hide errors with silent fallback or fake track data in production.
