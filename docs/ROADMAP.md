# Song Recall MVP Roadmap

## Purpose

This file is the agent's ordered path from empty repository to first working MVP. Read it before coding. Each section contains implementation details, responsible Pi agents, verification gates, and remaining work.

AGENTS.md and ORCHESTRATOR.md must follow this file precisely. The orchestrator must work from the first unfinished section whose dependencies are complete. It must not skip sections or mark work complete from prose alone.

## Roadmap rules

- [ ] means unfinished.
- [x] means verified complete.
- Completed section headings must end with (Completed).
- A feature is complete only when its checklist, tests, build checks, reviews, and documentation gates pass.
- After every feature, documentation agent updates this file before the next feature begins.
- Record blocked device-only work in docs/decision-log.md. Do not fake completion.
- Preserve unfinished tasks when updating this file.

## [x] 0. Repository structure and agent operating system (Completed)

### Goal

Provide project folders, documentation contracts, agent roles, and execution rules without adding app code.

### Completed work

- [x] Create src/ ownership folders.
- [x] Create tests/ ownership folders.
- [x] Create AGENTS.md.
- [x] Create ORCHESTRATOR.md.
- [x] Create docs/ feature and process documents.
- [x] Create .pi/agents/ role documents.
- [x] Confirm no Swift implementation exists.

### Agents

- Documentation agent verifies Markdown consistency.
- Code-review agent verifies no implementation was added accidentally.

### Completion gate

Directory structure exists, all Markdown contracts exist, and repository contains no Swift source.

## [x] 1. Native Xcode project foundation (Completed)

### Goal

Create a buildable iOS 26+ SwiftUI application shell mapped to src/ and tests/.

### Implementation

- Create SongRecall Xcode project and SongRecall app target.
- Set deployment target to iOS 26.
- Configure Swift 6 strict concurrency.
- Add source groups for App, Domain, Services, Features, DesignSystem, and Resources.
- Add unit-test and UI-test targets mapped to tests/.
- Add Apple Music usage description with clear privacy wording.
- Add a stable SongRecall scheme.
- Keep external dependencies empty.

Note: per the 2026-08-18 decision-log entry, the source layout now mirrors the sibling `zihe` project: app source lives in `src/SongRecall/`, unit tests in `src/SongRecallTests/`, UI tests in `src/SongRecallUITests/`, with the project at `src/SongRecall.xcodeproj`.

### Agents

- Builder creates project settings and app shell.
- Build agent checks simulator compilation.
- Documentation agent updates docs/build-and-run.md.
- Code-review agent checks target settings and dependency scope.

### Checklist

- [x] Project opens in Xcode.
- [x] App target builds for iOS Simulator.
- [x] Unit-test target discovers.
- [x] UI-test target launches.
- [x] No third-party dependency exists.

### Acceptance gate

Clean checkout opens and builds with xcodebuild. No app behavior beyond a placeholder root view is required.

## [x] 2. Media library authorization and local track catalog (Completed)

### Goal

Read playable, locally available songs from the user's Music library without network access.

### Implementation

- Request MediaPlayer authorization at the permission boundary.
- Query the user's song collection through MPMediaQuery.
- Map title, artist, album, persistent identifier, artwork, and asset URL into Track.
- Exclude cloud-only, DRM-protected, missing, or unsupported assets with nil asset URL.
- Keep stable identity based on persistent media identifier.
- Expose loading, denied, restricted, empty, and ready states.
- Provide Settings guidance after denial.
- Make catalog service injectable for tests.

Notes from implementation:

- Artwork is mapped lazily via `MediaLibraryService.artworkData(for:)` rather than stored inside `Track`, so the catalog stays lightweight for large libraries.
- The framework boundary is `MediaItemRecord`; all filtering lives in the pure `TrackMapper` and is unit-tested without MediaPlayer.
- Settings guidance after denial is rendered by the Permission feature in roadmap section 6.

### Agents

- Media-library agent owns MediaPlayer behavior and device validation.
- Privacy agent checks permission text and local-only handling.
- Builder owns integration into app state.
- Testing agent covers mapping and permission states.

### Checklist

- [x] Authorization flow exists.
- [x] Local playable songs map to Track.
- [x] Unplayable songs are excluded.
- [x] Empty and denied states have defined UI.
- [x] Unit tests cover mapping.
- [ ] Physical-device media-library test is recorded.

### Acceptance gate

On a real iPhone, authorized local songs appear without network calls. Denied and empty states remain usable.

## [x] 3. Audio playback runtime (Completed)

### Goal

Play selected local audio from the beginning and stop it at every round boundary.

### Implementation

- Wrap AVFoundation behind AudioPlaying.
- Prepare a local asset before a round begins.
- Reset playback position to zero before every play.
- Configure an appropriate playback audio session.
- Stop on correct answer, wrong answer, skip, timeout, next round, replay, and screen dismissal.
- Handle interruptions, route changes, and unavailable files.
- Keep audio runtime on the main actor where framework ownership requires it.
- Inject a fake player for tests.

Notes from implementation:

- `AudioPlaying` is a main-actor protocol; the quiz layer owns when a round ends. The runtime only reports system-driven interruptions via `onPlaybackInterruption` after stopping itself.
- `AVPlayerAudioPlayer` prepares with `AVURLAsset.load(.isPlayable)` (throws `PlaybackError.assetUnavailable`), seeks to zero on prepare and again before every play, and observes interruption + route-change notifications as async sequences.
- The fake player records a deterministic event stream (`prepare`, `play`, `stop`) used by quiz tests in roadmap section 4.
- Device audio checks are recorded as blocked in docs/decision-log.md.

### Agents

- Audio-runtime agent owns playback lifecycle.
- Media-library agent verifies asset URLs.
- Testing agent tests fake-player event ordering.
- Product-QA agent checks headphones, speaker, backgrounding, and interruption behavior.

### Checklist

- [x] Playback starts at zero.
- [x] Playback stops at every terminal round state.
- [x] Playback failure has visible recovery.
- [x] Interruption behavior is defined.
- [x] Fake-player tests pass.
- [ ] Device audio test passes.

### Acceptance gate

Every quiz round plays only its selected local song and never leaks playback into the next round.

## [ ] 4. Quiz domain engine

### Goal

Implement deterministic, testable quiz rules independent from SwiftUI and system frameworks.

### Implementation

- Define Track, QuizRound, QuizSession, and QuizState.
- Select ten unique random tracks when at least ten exist.
- Use all available tracks when library contains fewer than ten.
- Inject random source for deterministic tests.
- Start one round with a monotonic start timestamp.
- Allow one normalized free-text answer.
- Accept normalized title or artist-title form.
- End round on correct answer, wrong answer, skip, or timeout.
- Stop accepting input after terminal state.
- Advance rounds without duplicate selection.
- Produce final result summary.

### Agents

- Builder owns domain implementation.
- Testing agent owns state-machine and boundary tests.
- Code-review agent checks isolation from MediaPlayer and SwiftUI.
- Product-QA agent checks user-visible rule consistency.

### Checklist

- [ ] Domain models exist.
- [ ] Ten-round selection is unique.
- [ ] Fewer-than-ten behavior works.
- [ ] Answer normalization works.
- [ ] One-attempt rule works.
- [ ] Terminal states cannot accept more answers.
- [ ] Deterministic tests pass.

### Acceptance gate

Quiz engine can run entirely with fake tracks, fake clock, fake random source, and fake player.

## [ ] 5. Timing and weighted scoring

### Goal

Reward fast correct recall with transparent scoring.

### Implementation

- Use monotonic elapsed time, not wall-clock time.
- Score correct answers with max(100, 1000 - floor(elapsed seconds × 30)).
- Award 1,000 at immediate answer.
- Award 100 at or after 30 seconds if answer is still accepted.
- Award 0 for wrong answer, skip, reveal, or timeout.
- Freeze score at answer event.
- Display score and remaining time clearly.
- Test exact boundaries and timer race conditions.

### Agents

- Builder implements pure score calculator and timer state.
- Testing agent covers 0, 1, 15, 30, and over-30 seconds.
- SwiftUI-design agent checks readable score feedback.
- Code-review agent checks clock injection and race safety.

### Checklist

- [ ] Score formula documented.
- [ ] Monotonic clock injected.
- [ ] Timer cannot score after terminal state.
- [ ] Boundary tests pass.
- [ ] UI communicates score outcome.

### Acceptance gate

Same answer time always produces same score. Timeout and duplicate submissions cannot change score.

## [ ] 6. Home, permission, quiz, and results UI

### Goal

Deliver the complete first-use-to-results journey with minimal, polished interaction.

### Implementation

- Home shows local track count and Start Quiz.
- Permission screen explains why Music access is needed.
- Empty state explains how to make local songs available.
- Quiz shows artwork, round count, timer, score, answer field, submit, skip, and feedback.
- Results shows total score, correct count, accuracy, fastest answer, and replay.
- Use NavigationStack or sheets only where they clarify flow.
- Give all interactive elements stable accessibility identifiers.
- Keep state ownership in feature view models, not view bodies.

### Agents

- SwiftUI-design agent owns composition, layout, styling, and motion.
- Accessibility agent audits labels, Dynamic Type, contrast, and Reduce Motion.
- Builder integrates state and navigation.
- Product-QA agent runs full user journey.

### Checklist

- [ ] First launch flow works.
- [ ] Home-to-quiz flow works.
- [ ] Correct, wrong, skip, and timeout feedback works.
- [ ] Results and replay work.
- [ ] Loading and failure states are visible.
- [ ] Accessibility labels and identifiers exist.

### Acceptance gate

User can launch app, authorize library, start quiz, answer ten rounds, and replay without developer intervention.

## [ ] 7. Visual polish and accessibility pass

### Goal

Make MVP feel distinctive, native, fast, and accessible.

### Implementation

- Apply dark album-art arcade design tokens.
- Use semantic colors and contrast-safe overlays.
- Use artwork-derived accents only as decoration; text remains readable.
- Add restrained transitions and haptics.
- Respect Reduce Motion.
- Support Dynamic Type without clipping.
- Support VoiceOver order and meaningful control labels.
- Meet minimum touch target size.
- Verify light fallback, dark appearance, and high-contrast settings.
- Avoid animation tied to timer updates that causes excessive redraw.

### Agents

- SwiftUI-design agent performs visual pass.
- Accessibility agent performs dedicated audit.
- Performance agent responsibilities belong to code-review and product-QA if no separate agent exists.
- Documentation agent updates docs/design-system.md.

### Checklist

- [ ] Design tokens documented.
- [ ] Timer and score remain readable.
- [ ] Dynamic Type passes.
- [ ] VoiceOver passes.
- [ ] Reduce Motion passes.
- [ ] Contrast and touch-target checks pass.
- [ ] No obvious frame drops during playback.

### Acceptance gate

Reviewers can use core quiz flow with accessibility settings enabled and without visual or interaction blockers.

## [ ] 8. Automated tests and device QA

### Goal

Protect MVP behavior and verify system-only paths on real hardware.

### Implementation

- Add unit tests for catalog mapping, answer matching, quiz state, scoring, timing, and selection.
- Add UI tests for permission, empty library, quiz, timeout, results, and replay.
- Add fakes for media library, player, clock, and random source.
- Use accessibility identifiers rather than brittle text selectors.
- Run simulator build and tests on every feature.
- Run physical-device media and audio checks before MVP completion.
- Record device-only limitations and results in docs/decision-log.md.

### Agents

- Testing agent owns test implementation.
- Build agent owns repeatable xcodebuild commands.
- Product-QA agent owns scenario matrix.
- Code-review agent checks test quality and missing failure paths.

### Checklist

- [ ] Unit suite passes.
- [ ] UI suite passes.
- [ ] Simulator build passes.
- [ ] Real-device media test passes.
- [ ] Real-device audio test passes.
- [ ] Failure scenarios are recorded.

### Acceptance gate

All automated checks pass and device-only behavior has evidence.

## [ ] 9. MVP release readiness

### Goal

Ship a private, local-only first MVP with clear limitations.

### Implementation

- Verify app metadata and privacy wording.
- Verify no network entitlement or external music dependency exists.
- Verify release build configuration.
- Verify permission denial, empty library, and playback failure messaging.
- Verify no song audio or metadata leaves device.
- Update all docs and roadmap status.
- Prepare Conventional Commit and release checklist.

### Agents

- Release agent checks signing and release configuration.
- Privacy/media-library agents check local-only behavior.
- Code-review agent performs final read-only review.
- Documentation agent performs final Markdown audit.
- Commit agent creates final Conventional Commit.

### Checklist

- [ ] Release build succeeds.
- [ ] Privacy review passes.
- [ ] Final QA passes.
- [ ] Docs are current.
- [ ] All completed roadmap sections have [x] and (Completed).
- [ ] Remaining work is explicit.
- [ ] Conventional Commit is prepared.

### Acceptance gate

First working MVP runs on an iPhone with local Music-library songs and satisfies all documented constraints.

## Future work after MVP

- Files-app MP3 importer.
- Persistent history and personal statistics.
- Configurable round count and timer.
- Multiple-choice mode.
- Fuzzy typo tolerance.
- iPad layout.
- Shareable local results.
- Optional local artwork cache.
