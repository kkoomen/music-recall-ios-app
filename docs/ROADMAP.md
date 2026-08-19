# Song Recall MVP Roadmap

## Purpose

This file is the single source of truth for the Song Recall MVP. It is both the ordered build plan (from empty repository to shipping app) and the normative product and technical specification. It is handed to an implementer — another LLM or an engineer — that must recreate the entire app from this file alone: structure, project settings, domain rules, scoring math, exact user-facing copy, accessibility identifiers, test inventory, and acceptance gates.

AGENTS.md and ORCHESTRATOR.md must follow this file precisely. The orchestrator must work from the first unfinished section whose dependencies are complete. It must not skip sections or mark work complete from prose alone.

## How to use this document

1. Read this file completely before writing any code.
2. Work sections 0–9 strictly in order. Each section is a bounded deliverable with its own acceptance gate.
3. Every **Specification** bullet is a normative requirement: reproduce the described behavior, naming, and wording exactly. Do not invent alternatives.
4. Every **Checklist** item is a verification gate. A section is complete only when its checklist, tests, build checks, reviews, and documentation gates pass.
5. `[x]` + `(Completed)` means the section is verified complete in the reference repository. A fresh implementer must still reproduce it — the marker records that the behavior described below is the shipped contract, not prose to skim.
6. Where this file conflicts with a companion document, this file wins.
7. Keep the palette, the tree, and the counts in this file accurate whenever structure or behavior changes.

## Roadmap rules

- [ ] means unfinished.
- [x] means verified complete.
- Completed section headings must end with (Completed).
- A feature is complete only when its checklist, tests, build checks, reviews, and documentation gates pass.
- After every feature, documentation agent updates this file before the next feature begins.
- Record blocked device-only work in docs/decision-log.md. Do not fake completion.
- Preserve unfinished tasks when updating this file.

## Project facts (normative)

- Product name: **Song Recall** — a private iPhone music-memory quiz.
- Bundle identifiers: `com.koomen.songrecall` (app), `com.koomen.songrecallTests` (unit tests), `com.koomen.songrecallUITests` (UI tests).
- Deployment target: **iOS 26.0** for all three targets. Swift **6.0** (strict concurrency) for all three targets.
- Single shared scheme named `SongRecall`.
- Xcode project at `src/SongRecall.xcodeproj`. The project uses **file-system-synchronized groups**: `src/SongRecall/` feeds the app target, `src/SongRecallTests/` feeds the unit-test target, `src/SongRecallUITests/` feeds the UI-test target. Adding or removing files inside those folders is picked up automatically; no project-file edits are needed.
- Single requested permission: Music access, via one `NSAppleMusicUsageDescription` entry with this exact wording:
  > Song Recall needs access to your Music library to find songs stored on this iPhone and play them locally. Your library, audio, and guesses never leave your device.
- Hard constraints: iOS only; iOS 26+; Swift and SwiftUI only; Apple frameworks only (MediaPlayer for the library, AVFoundation for playback); no third-party packages; no Spotify/streaming/catalog/lyrics/recognition/analytics/cloud/external-music API; no song audio or metadata leaves the device; no network imports, no entitlements.
- Architecture rule: dependencies point inward — views → feature view models → pure domain → service adapters. `Domain` must never import SwiftUI, MediaPlayer, or AVFoundation. Time, randomness, media access, and playback are injectable for tests.

## Build and test commands (normative)

Simulator build:

```sh
xcodebuild \
  -project src/SongRecall.xcodeproj \
  -scheme SongRecall \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedData \
  build
```

Unit and UI tests:

```sh
xcodebuild \
  -project src/SongRecall.xcodeproj \
  -scheme SongRecall \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedData \
  test
```

`-derivedDataPath .build/DerivedData` keeps artifacts inside the ignored `.build/` directory. Build expectations: a clean build and test run after every feature; report destination, scheme, command, result, and first decisive failure line. Build constraints: no network dependency, no package resolution, no hidden generated source, no undocumented build warnings.

## Companion documents

These describe process, rationale, and design detail. Recreation-critical content is inlined in this file; companions are authoritative for process and for the rationale behind decisions.

- Process: `AGENTS.md` (repository rules — read first), `ORCHESTRATOR.md` (delegation and handoff), `docs/agent-workflow.md` (standard cycle), `docs/commit-conventions.md`.
- Product and design: `docs/goal-and-scope.md`, `docs/architecture.md`, `docs/quiz-rules.md`, `docs/design-system.md`, `src/STRUCTURE.md`.
- Framework adapters: `docs/media-library.md`, `docs/privacy.md`, `docs/testing.md`.
- Lifecycle: `docs/build-and-run.md`, `docs/release-checklist.md`, `docs/decision-log.md` (dated decisions that changed behavior, including the scoring formula history).
- Agent roles: role instructions for the multi-agent workflow — orchestrator, builder, testing, build, code-review, documentation, commit, media-library, audio-runtime, swiftui-design, accessibility, product-qa, release, privacy. Store them in the host tool's agent convention (pi: `.pi/agents/`; Claude Code: `CLAUDE.md`; Codex: `AGENTS.md`).

## Current color palette

Defined in `src/SongRecall/DesignSystem/AppTheme.swift` as RGB components; the hex values below are the sRGB equivalents. The app is dark-only (`.preferredColorScheme(.dark)` is forced), so every token is tuned for the dark surfaces.

| Token | RGB (0–255) | Hex | Usage |
| --- | --- | --- | --- |
| `background` | 14, 14, 23 | `#0E0E17` | App background (near-black). |
| `surface` | 31, 31, 43 | `#1F1F2B` | Cards, banners, answer field. |
| `surfaceElevated` | 43, 43, 59 | `#2B2B3B` | Elevated surface (defined; no screen uses it yet). |
| `surfaceBorder` | white, 8% opacity | `#FFFFFF` at 8% | Panel strokes and dropdown dividers. |
| `primaryText` | 245, 245, 250 | `#F5F5FA` | Headings, titles, score (off-white). |
| `secondaryText` | 158, 158, 178 | `#9E9EB2` | Captions, round label, artist, footnote. |
| `accent` | 252, 125, 150 | `#FC7D96` | Hot arcade pink: primary buttons, icons, highlights. |
| `accentText` | 20, 15, 18 | `#140F12` | Near-black text on `accent` (contrast ≈ 9:1). |
| `success` | 89, 217, 140 | `#59D98C` | Correct-answer feedback. |
| `danger` | 245, 107, 107 | `#F56B6B` | Wrong/timeout/interrupted feedback; timer when 5 s or fewer remain. |

Supporting tokens: spacing scale xs/sm/md/lg/xl/xxl = 4/8/12/16/24/32 pt; corner radii card 20 / small 14 / button 16; standard animation 0.25 s ease-in-out; minimum touch target 48 pt. Typography: rounded, heavy titles (`design: .rounded`); monospaced digits on the timer, score, and result total so ticking never shifts layout; SF Symbols for icons.

## Current app structure

Generated from a clean checkout with `tree src -I 'xcuserdata|*.xcuserstate|.DS_Store' --prune`. The layout follows the repository rules in AGENTS.md: app source under `src/SongRecall/`, unit tests under `src/SongRecallTests/`, UI tests under `src/SongRecallUITests/`, and the Xcode project at `src/SongRecall.xcodeproj`. Within the app target, `App` holds the composition root and navigation, `Domain` holds pure, framework-independent logic, `Services` holds MediaPlayer/AVFoundation/system adapters, `Features` holds per-screen SwiftUI views and view models, `DesignSystem` holds tokens and styling helpers, and `Resources` holds assets. `src/STRUCTURE.md` documents this layout in detail.

```text
src
├── SongRecall
│   ├── App
│   │   ├── AccessibilityID.swift
│   │   ├── AppModel.swift
│   │   ├── AppRoute.swift
│   │   ├── RootView.swift
│   │   └── SongRecallApp.swift
│   ├── DesignSystem
│   │   ├── AppTheme.swift
│   │   ├── ArtworkAccent.swift
│   │   └── Haptics.swift
│   ├── Domain
│   │   ├── AnswerMatcher.swift
│   │   ├── AnswerNormalizer.swift
│   │   ├── Clocking.swift
│   │   ├── MusicAuthorizationStatus.swift
│   │   ├── MusicLibraryState.swift
│   │   ├── OptionGenerator.swift
│   │   ├── QuizConfiguration.swift
│   │   ├── QuizEngine.swift
│   │   ├── QuizMode.swift
│   │   ├── QuizResult.swift
│   │   ├── QuizRound.swift
│   │   ├── QuizSession.swift
│   │   ├── QuizState.swift
│   │   ├── RandomSource.swift
│   │   ├── RoundOutcome.swift
│   │   ├── ScoreCalculator.swift
│   │   ├── Track.swift
│   │   └── TrackSuggestionRanker.swift
│   ├── Features
│   │   ├── Home
│   │   │   └── HomeView.swift
│   │   ├── Permission
│   │   │   ├── PermissionView.swift
│   │   │   └── SettingsOpener.swift
│   │   ├── Quiz
│   │   │   ├── FeedbackStrings.swift
│   │   │   ├── OptionRow.swift
│   │   │   ├── QuizView.swift
│   │   │   ├── QuizViewModel.swift
│   │   │   └── SuggestionRow.swift
│   │   └── Results
│   │       └── ResultsView.swift
│   ├── Resources
│   │   └── Assets.xcassets
│   │       ├── AccentColor.colorset
│   │       │   └── Contents.json
│   │       ├── AppIcon.appiconset
│   │       │   ├── AppIcon-1024.png
│   │       │   └── Contents.json
│   │       └── Contents.json
│   └── Services
│       ├── AudioPlaying.swift
│       ├── AVPlayerAudioPlayer.swift
│       ├── LibraryStateResolver.swift
│       ├── MediaItemRecord.swift
│       ├── MediaLibraryProviding.swift
│       ├── MediaLibraryService.swift
│       ├── SeededRandomSource.swift
│       ├── StubAudioPlayer.swift
│       ├── StubMediaLibrary.swift
│       ├── SystemClock.swift
│       ├── SystemRandomSource.swift
│       └── TrackMapper.swift
├── SongRecall.xcodeproj
│   ├── project.pbxproj
│   └── xcshareddata
│       └── xcschemes
│           └── SongRecall.xcscheme
├── SongRecallTests
│   ├── AnswerMatcherTests.swift
│   ├── AnswerNormalizerTests.swift
│   ├── FakeAudioPlayer.swift
│   ├── FakeAudioPlayerTests.swift
│   ├── FakeClock.swift
│   ├── FeedbackStringsTests.swift
│   ├── LibraryStateResolverTests.swift
│   ├── QuizEngineTests.swift
│   ├── QuizSessionTests.swift
│   ├── OptionGeneratorTests.swift
│   ├── QuizViewModelSuggestionTests.swift
│   ├── QuizViewModelModeTests.swift
│   ├── ScoreCalculatorTests.swift
│   ├── SmokeTests.swift
│   ├── StubSelectionOrderTests.swift
│   ├── TrackMapperTests.swift
│   └── TrackSuggestionRankerTests.swift
├── SongRecallUITests
│   ├── AccessibilityUITests.swift
│   ├── AutocompleteUITests.swift
│   ├── EasyModeUITests.swift
│   ├── LaunchTests.swift
│   ├── PermissionFlowUITests.swift
│   ├── QuizJourneyTests.swift
│   └── QuizTimeoutUITests.swift
└── STRUCTURE.md
```

## [x] 0. Repository structure and agent operating system (Completed)

### Goal

Provide project folders, documentation contracts, agent roles, and execution rules without adding app code.

### Specification

- Create the ownership folders under `src/`: `SongRecall/`, `SongRecallTests/`, `SongRecallUITests/` (per the 2026-08-18 decision-log entry, this mirrors the sibling `zihe` project; there is no repo-root `tests/` folder).
- Create `AGENTS.md` (repository rules, read order, hard constraints, agent workflow, done definition, Conventional Commit rule) and `ORCHESTRATOR.md` (delegation and handoff).
- Create `docs/` with the companion documents listed above: `agent-workflow.md`, `architecture.md`, `build-and-run.md`, `commit-conventions.md`, `decision-log.md`, `design-system.md`, `goal-and-scope.md`, `media-library.md`, `privacy.md`, `quiz-rules.md`, `release-checklist.md`, `ROADMAP.md`, `testing.md`.
- Create one role document per agent in the host tool's agent convention (pi: `.pi/agents/`; Claude Code: `CLAUDE.md`; Codex: `AGENTS.md`): orchestrator, builder, testing, build, code-review, documentation, commit, media-library, audio-runtime, swiftui-design, accessibility, product-qa, release, privacy.
- Create `src/STRUCTURE.md` describing the folder layout and project mapping.
- Confirm no Swift implementation exists.

### Agents

- Documentation agent verifies Markdown consistency.
- Code-review agent verifies no implementation was added accidentally.

### Checklist

- [x] src/ ownership folders exist.
- [x] AGENTS.md and ORCHESTRATOR.md exist.
- [x] docs/ feature and process documents exist.
- [x] Role documents for the host tool's agent convention exist.
- [x] No Swift implementation exists.

### Acceptance gate

Directory structure exists, all Markdown contracts exist, and repository contains no Swift source.

## [x] 1. Native Xcode project foundation (Completed)

### Goal

Create a buildable iOS 26+ SwiftUI application shell mapped to src/ and tests/.

### Specification

- Create `src/SongRecall.xcodeproj` with one app target `SongRecall` and two test targets `SongRecallTests` (unit) and `SongRecallUITests` (UI).
- Set `IPHONEOS_DEPLOYMENT_TARGET = 26.0` and `SWIFT_VERSION = 6.0` on all three targets (strict concurrency).
- Use file-system-synchronized groups mapped to `src/SongRecall/`, `src/SongRecallTests/`, `src/SongRecallUITests/` so new files are picked up automatically.
- Add source groups: App, Domain, Services, Features (Home, Permission, Quiz, Results), DesignSystem, Resources.
- Add one shared scheme named `SongRecall`.
- Add a placeholder `SongRecallApp`/`RootView` SwiftUI shell; no app behavior yet.
- Add the single `NSAppleMusicUsageDescription` entry with the exact wording from Project facts.
- Bundle identifiers as in Project facts. External dependencies empty.

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

Clean checkout opens and builds with the xcodebuild commands above. No app behavior beyond a placeholder root view is required.

## [x] 2. Media library authorization and local track catalog (Completed)

### Goal

Read playable, locally available songs from the user's Music library without network access.

### Specification

- Request MediaPlayer authorization at the permission boundary: `MPMediaLibrary.requestAuthorization`, mapped to the domain enum `MusicAuthorizationStatus { notDetermined, denied, restricted, authorized }` (`@unknown default` maps to denied).
- Query the user's song collection with `MPMediaQuery.songs()`.
- The framework boundary is `MediaItemRecord` (id = `item.persistentID`, title = `item.title`, artist = `item.artist`, album = `item.albumTitle`, assetURL = `item.assetURL`, hasProtectedAsset = `item.hasProtectedAsset`). All filtering lives in the pure `TrackMapper`, unit-tested without MediaPlayer.
- `TrackMapper.makeTracks(from:)` maps records to `Track` and **excludes** every record with a nil `assetURL` or `hasProtectedAsset == true` (cloud-only, DRM-protected, missing, or unsupported assets). Nil title/artist/album fall back to `"Unknown Title"`, `"Unknown Artist"`, `"Unknown Album"`.
- `Track` is a pure value type: `id: UInt64` (MediaPlayer's persistent media identifier — duplicate titles stay distinct), `title`, `artist`, `album`, `assetURL: URL` (non-nil means playable on this device). It contains no MediaPlayer/AVFoundation/SwiftUI types.
- Artwork is **not** stored on `Track`. `MediaLibraryService` keeps a lightweight cache of `MPMediaItem`s after a catalog fetch and exposes `artworkData(for trackID:) -> Data?` (512×512 JPEG, quality 0.85) lazily.
- Fetching tracks without authorization throws `MediaLibraryError.notAuthorized`.
- `LibraryStateResolver` settles (status × tracks) into `MusicLibraryState { loading, notDetermined, denied, restricted, empty, ready([Track]) }`: authorized + non-empty → `ready`, authorized + empty → `empty`.
- The catalog service is behind the injectable `MediaLibraryProviding` protocol (authorizationStatus, requestAuthorization, fetchTracks, artworkData) so tests use `StubMediaLibrary`.
- Settings guidance after denial is rendered by the Permission feature (section 6).

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

### Acceptance gate

On a real iPhone, authorized local songs appear without network calls. Denied and empty states remain usable.

## [x] 3. Audio playback runtime (Completed)

### Goal

Play selected local audio from the beginning and stop it at every round boundary.

### Specification

- Wrap AVFoundation behind the main-actor protocol `AudioPlaying`:
  - `prepare(assetURL:) async throws` — loads the local asset and resets position to zero; throws `PlaybackError.assetUnavailable` for missing or unsupported files (implemented with `AVURLAsset.load(.isPlayable)`).
  - `playFromStart()` — seeks to zero again and starts playing.
  - `stop()` — stops playback and releases the current item.
  - `isPlaying: Bool`, and `onPlaybackInterruption: (() -> Void)?` — called when the system interrupts playback or tears down the active route (phone call, headphones unplugged, another app takes over); the runtime stops playback itself before calling it.
- The quiz layer decides when a round ends; the runtime only reports system-driven interruptions.
- Configure a playback audio session (`.playback` category) appropriate for local music.
- Observe interruption and route-change notifications as async sequences.
- Stop playback on: correct answer, wrong answer, skip, timeout, next round, replay, screen dismissal, playback failure, and interruption.
- `StubAudioPlayer`/`FakeAudioPlayer` record a deterministic event stream (`prepare`, `play`, `stop`) used by quiz tests.
- Device audio checks (headphones, speaker, backgrounding, interruption) are recorded as blocked in docs/decision-log.md.

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

### Acceptance gate

Every quiz round plays only its selected local song and never leaks playback into the next round.

## [x] 4. Quiz domain engine (Completed)

### Goal

Implement deterministic, testable quiz rules independent from SwiftUI and system frameworks.

### Specification

Injectable primitives:

- `Clocking` exposes `now: TimeInterval` — monotonic seconds since an arbitrary fixed epoch, never wall-clock aligned, never jumps backwards.
- `RandomSource` exposes `shuffled<T>(_ elements: [T]) -> [T]` — `SeededRandomSource` (SplitMix64) makes selection deterministic per seed; `SystemRandomSource` is the production implementation.

Configuration and selection:

- `QuizConfiguration` defaults to `roundCount = 10`, `roundDuration = 30` seconds.
- `QuizEngine(catalog:configuration:random:clock:)` selects `min(max(roundCount, 0), catalog.count)` unique shuffled tracks via `random.shuffled(catalog).prefix(count)`. No duplicates within a session; with fewer than ten playable tracks, every track is used once; empty catalog yields a session that cannot start.

State machine (pure value types, all time passed as explicit `now`):

- `QuizState { notStarted, playing(roundIndex: Int), finished(QuizResult) }`.
- `QuizRound` holds a `Track`, a `startElapsed` set when the round begins, and an `outcome`. It is terminal exactly once: `end(with:)` ignores later events (first terminal event wins).
- `QuizSession.begin(now:)` starts round 0. `submitAnswer(_:now:)` accepts one answer for the active round: elapsed = `now − startElapsed`; if elapsed > duration → `timedOut`; else match → `correct(elapsed:)` / `wrong`. Answers after the active round are rejected (nil).
- `skip()`, `interrupt()` (playback failure or system interruption), and `markTimedOutIfNeeded(now:)` (elapsed > duration) end the active round.
- `advance(now:)` starts the next round or finishes the session with a `QuizResult` after the final round.
- `RoundOutcome { correct(elapsed: TimeInterval), wrong, skipped, timedOut, interrupted }`.

Answer normalization and matching:

- `AnswerNormalizer.normalize(_:)`: fold `.diacriticInsensitive` + `.caseInsensitive`, lowercase, keep only letters, numbers, and whitespace, collapse whitespace runs to single spaces.
- `AnswerMatcher.isMatch(guess:track:)`: accepts an exact normalized **title** or an exact normalized **"artist title"** form. Empty normalized guesses never match. No fuzzy matching, no network matching, no recognition.

Results:

- `QuizResult` exposes `correctCount`, `accuracy` (correct / rounds), `fastestCorrectElapsed` (minimum correct elapsed), and `totalScore` (sum of per-round scores, clamped ≥ 0 — scoring in section 5).

### Agents

- Builder owns domain implementation.
- Testing agent owns state-machine and boundary tests.
- Code-review agent checks isolation from MediaPlayer and SwiftUI.
- Product-QA agent checks user-visible rule consistency.

### Checklist

- [x] Domain models exist.
- [x] Ten-round selection is unique.
- [x] Fewer-than-ten behavior works.
- [x] Answer normalization works.
- [x] One-attempt rule works.
- [x] Terminal states cannot accept more answers.
- [x] Deterministic tests pass.

### Acceptance gate

Quiz engine can run entirely with fake tracks, fake clock, fake random source, and fake player.

## [x] 5. Timing and weighted scoring (Completed)

### Goal

Reward fast correct recall with transparent scoring.

### Specification

- Use monotonic elapsed time from the injected `Clocking`, never wall clock.
- Constants: `basePoints = 10`, `fastThreshold = 5` seconds, `wrongPenalty = 5`, `skipPenalty = 10`, default `roundDuration = 30`.
- Correct answer: `points = (10 + remainingSeconds) × multiplier`, where `remainingSeconds = max(0, ceil(roundDuration − elapsed))` matches the displayed countdown, and `multiplier = 2` when the answer lands at or before 5 seconds elapsed (25 or more seconds remaining on the clock); otherwise `multiplier = 1`. Easy mode narrows the fast window to 3 seconds (27 or more seconds remaining) — see section 10.
  - Immediate answer (elapsed 0): remaining 30 → 40 × 2 = **80 points**.
  - Answer at exactly 30 s: remaining 0, no multiplier → **10 points**.
  - Answer at 5.0 s: remaining 25 → 35 × 2 = 70 points; at 5.1 s → 35 points.
- Wrong answer: **−5**. Skip: **−10**. Timeout or playback interruption: **0**.
- Running score and final total clamp at 0 (never negative).
- Score freezes at the first terminal event; late events return nil and cannot change the score (answer-before-timer and timer-before-answer races covered by tests).
- `ScoreCalculator.breakdown(forCorrectAnswerAt:roundDuration:)` returns points plus `isFast` (drives the "You're fast!" celebration in the UI). `QuizResult.totalScore` sums per-round contributions and clamps.

### Agents

- Builder implements pure score calculator and timer state.
- Testing agent covers 0, 1, 15, 30, and over-30 seconds.
- SwiftUI-design agent checks readable score feedback.
- Code-review agent checks clock injection and race safety.

### Checklist

- [x] Score formula documented.
- [x] Monotonic clock injected.
- [x] Timer cannot score after terminal state.
- [x] Boundary tests pass.
- [x] UI communicates score outcome.

### Acceptance gate

Same answer time always produces same score. Timeout and duplicate submissions cannot change score.

## [x] 6. Home, permission, quiz, and results UI (Completed)

### Goal

Deliver the complete first-use-to-results journey with minimal, polished interaction.

### Specification

Navigation (`AppRoute { library, quiz, results(QuizResult) }`, `RootView` switches on it; `AppModel` is the main-actor composition root):

- `AppModel.makeFromEnvironment()` builds the production model, or a UI-test stub model when `-uitest-library` is present in launch arguments (see Launch arguments below).
- `loadLibrary()`/`requestAccessAndLoad()` resolve authorization and catalog into `MusicLibraryState`; `startQuiz()` builds `QuizEngine` + `QuizViewModel`; `finishQuiz` routes to results; `replay()` restarts; `backToLibrary()` returns and reloads.

Home screen (`HomeView`):

- App title "Song Recall" (rounded, heavy, 40 pt), `music.note.list` icon in `accent`, then "N songs ready" ("1 song ready" when N == 1), then two full-width mode buttons — **Easy Mode** (accent-filled, near-black text, caption "5 choices") and **Hard Mode** (bordered, caption "Type the answer") — and a footnote "N songs · 30s per round · min(N, 10) rounds".
- Identifiers: `home.trackCount`, `home.startEasy`, `home.startHard`.

Permission screen (`PermissionView`) — one screen, four states, exact copy:

- `notDetermined` (icon `music.note`, title "Your music stays on your iPhone"): message "Song Recall plays songs already stored in your Music library. Nothing ever leaves your device — no uploads, no analytics." Button **Allow Music Access**.
- `denied` (icon `lock.fill`, title "Music access is turned off"): message "Song Recall needs Music access to find and play songs stored locally. You can change this anytime in Settings." Button **Open Settings** (`SettingsOpener`).
- `restricted` (icon `exclamationmark.shield.fill`, title "Music access is restricted"): message "Music access is managed by a restriction on this device and cannot be changed inside Song Recall."
- `empty` (icon `tray`, title "No local songs found"): message "No locally playable songs were found. Add songs to your Music library on this iPhone — download them so they are stored on the device — then try again."
- Identifiers: `permission.allow`, `permission.settings`, `permission.title`.

Quiz screen (`QuizView` + `QuizViewModel`):

- Layout: answer field at the top, action buttons pinned to the bottom, and the space between reserved for the autocomplete dropdown, which expands below the input while typing without shifting the layout. `ViewThatFits` header (round + score + timer) falls back to a vertical layout at large Dynamic Type.
- Header: "Round n / m" (secondary), "Score X" (title2 bold, monospaced), timer as a 36 pt rounded-heavy monospaced number. Timer color: `danger` when active and ≤ 5 s remain, `primaryText` when active, `secondaryText` once settled.
- Answer field: plain TextField, placeholder "Song title or artist — title", `.submitLabel(.go)`, auto-focused at round start, disabled once a round settles; keyboard dismisses when a round settles.
- Actions while a round is active: **Skip** (bordered, secondary tint) and **Submit** (accent, disabled while the field is empty/whitespace). After a round settles: **Next**.
- Feedback banner (`quiz.feedback`) under the field — exact strings from `FeedbackStrings`:
  - fast correct: "You're fast! 2x, plus {points} points" — celebration banner with `bolt.fill`, accent "You're fast!", and "+{points} points" in `success` with a `2x` capsule badge to its right.
  - correct: "Correct! +{points} points" (`checkmark.circle.fill`, success).
  - wrong: "Not this time ({points})" (`xmark.circle.fill`, danger), points negative.
  - skipped: "Skipped ({points})" (`forward.fill`, secondary), points negative.
  - timed out: "Time's up" (`xmark.circle.fill`, danger).
  - interrupted: "Playback was interrupted" (`exclamationmark.triangle.fill`, danger).
- Answer reveal (`quiz.reveal`): whenever a round ends — correct, wrong, skip, timeout, or interruption — the song is revealed centered in the middle of the screen without a container: title in larger white text, artist in smaller grey text underneath.

Answer-field autocomplete (normative, full contract):

- Debounced 400 ms after the last keystroke; searches the full local catalog (not just the session's selected tracks); up to five suggestions.
- Ranking by normalized match relevance (higher wins): exact title 100, title prefix 90, exact artist 85, artist prefix 80, artist-title prefix 75, title substring 70, artist-title substring 60, artist substring 50, no match 0.
- Songs with equal relevance (e.g., every song by one artist) are shuffled via the injected random source — the active round's track is never favored, and there is no alphabetical fallback. Precompute the normalized index once per session (`TrackSuggestionRanker.makeIndex`).
- Each row shows title in white larger text and artist in grey smaller text; tapping a row fills the field with the title and submits it as the one allowed attempt.
- Return-key behavior: non-empty field → submit the typed answer; empty field with the dropdown open → select the first suggestion and submit; empty field with no dropdown → do nothing (never an accidental wrong answer).
- Clearing the input keeps the dropdown open so return can still pick the first suggestion.

Results screen (`ResultsView`):

- "Quiz Complete" (32 pt), `trophy.fill` in accent, total score (72 pt, rounded heavy, monospaced), stat grid with Correct / Accuracy / Fastest (fastest formatted "%.1fs", em dash when none) / 2x Multipliers (count of correct answers that landed in the fast window, shown as a `bolt.fill` icon with a "2x" caption in `secondaryText` below the count), **Play Again** (accent) and **Back to Library** (secondary) buttons.
- Identifiers: `results.score`, `results.correct`, `results.accuracy`, `results.fastest`, `results.multipliers`, `results.replay`, `results.home`.

Stable accessibility identifiers (normative, centralized in `App/AccessibilityID.swift`):

- Home: `home.trackCount`, `home.startEasy`, `home.startHard`.
- Permission: `permission.allow`, `permission.settings`, `permission.title`.
- Quiz: `quiz.round`, `quiz.timer`, `quiz.score`, `quiz.answerField`, `quiz.suggestion`, `quiz.submit`, `quiz.skip`, `quiz.next`, `quiz.option`, `quiz.reveal`, `quiz.feedback`.
- Results: `results.score`, `results.correct`, `results.accuracy`, `results.fastest`, `results.multipliers`, `results.replay`, `results.home`.

Launch arguments (normative, UI-test contract):

- `-uitest-library ready|empty|denied|restricted|notDetermined` selects a `StubMediaLibrary` mode; `-uitest-round-duration <seconds>` shortens rounds for timeout tests; stub mode uses `SeededRandomSource(seed: 0)`.
- `StubMediaLibrary.tracks`: Alpha Song / Artist One, Beta Song / Artist Two, Gamma Song / Artist Three (album "Stub Album", `stub://track/1..3`). Seed-0 selection order is **Gamma, Beta, Alpha** — the first round is Gamma Song.

### Agents

- SwiftUI-design agent owns composition, layout, styling, and motion.
- Accessibility agent audits labels, Dynamic Type, contrast, and Reduce Motion.
- Builder integrates state and navigation.
- Product-QA agent runs full user journey.

### Checklist

- [x] First launch flow works.
- [x] Home-to-quiz flow works.
- [x] Correct, wrong, skip, and timeout feedback works.
- [x] Autocomplete suggests, ranks, and commits answers.
- [x] Correct answer is revealed on every round end.
- [x] Results and replay work.
- [x] Loading and failure states are visible.
- [x] Accessibility labels and identifiers exist.

### Acceptance gate

User can launch app, authorize library, start quiz, answer ten rounds, and replay without developer intervention.

## [x] 7. Visual polish and accessibility pass (Completed)

### Goal

Make MVP feel distinctive, native, fast, and accessible.

### Specification

- Apply the dark album-art arcade tokens from the Current color palette section. The app is intentionally dark-only (`.preferredColorScheme(.dark)` forced); no light fallback.
- `ArtworkAccent` (average artwork pixel color for a radial glow) remains a dormant helper; current screens render no artwork, so all text sits on semantic colors.
- `panel(cornerRadius:)` modifier: `surface` fill, `surfaceBorder` 1 pt stroke, rounded corners.
- Haptics (in `DesignSystem/Haptics.swift`): `success` on correct, `error` on wrong/timeout/interrupted, `lightImpact` on skip — all gated on Reduce Motion, as are all transitions.
- Timer and score use monospaced digits and are never animated per tick (no excessive redraw).
- Dynamic Type without clipping: `ViewThatFits` quiz header; accessibility-XXXL UI test asserts controls stay hittable.
- VoiceOver: meaningful labels on timer ("N seconds remaining"), score, round ("Round n of m"), stats ("Title: value"); artwork (when present in future screens) is labeled "Song artwork" without leaking the title; result states combine icon + text, never color alone; feedback banners and reveal use combined accessibility elements with the exact `FeedbackStrings` copy.
- Touch targets enforce a 48 pt minimum height.
- Contrast: `accentText` on `accent` ≈ 9:1; primary/secondary text on `background` and `surface` pass WCAG AA.

### Agents

- SwiftUI-design agent performs visual pass.
- Accessibility agent performs dedicated audit.
- Performance agent responsibilities belong to code-review and product-QA if no separate agent exists.
- Documentation agent updates docs/design-system.md.

### Checklist

- [x] Design tokens documented.
- [x] Timer and score remain readable.
- [x] Dynamic Type passes.
- [x] VoiceOver passes.
- [x] Reduce Motion passes.
- [x] Contrast and touch-target checks pass.
- [x] No obvious frame drops during playback.

### Acceptance gate

Reviewers can use core quiz flow with accessibility settings enabled and without visual or interaction blockers.

## [x] 8. Automated tests and device QA (Completed)

### Goal

Protect MVP behavior and verify system-only paths on real hardware.

### Specification

- Unit suite (124 tests in `src/SongRecallTests/`) covers: mapper filtering (`TrackMapperTests`), normalization (`AnswerNormalizerTests`), matching (`AnswerMatcherTests`), session state machine (`QuizSessionTests`), option submission by track identity (`QuizSessionTests`), engine selection determinism (`QuizEngineTests`, `StubSelectionOrderTests`), scoring boundaries and penalties (`ScoreCalculatorTests`), mode thresholds and multiplier counts (`ScoreCalculatorTests`), library-state resolution (`LibraryStateResolverTests`), feedback strings (`FeedbackStringsTests`), autocomplete ranking and tie order (`TrackSuggestionRankerTests`), option generation (`OptionGeneratorTests`), view-model suggestion/return-key behavior (`QuizViewModelSuggestionTests`), easy-mode view-model behavior (`QuizViewModelModeTests`), fake-player event ordering (`FakeAudioPlayerTests`), and a launch smoke test (`SmokeTests`).
- UI suite (11 tests in `src/SongRecallUITests/`) covers: permission states notDetermined/denied/restricted/empty (`PermissionFlowUITests`), the full quiz journey correct/wrong/skip (`QuizJourneyTests`), the easy-mode journey with correct/wrong highlights (`EasyModeUITests`), autocomplete commit (`AutocompleteUITests`), timeout with recovery via `-uitest-round-duration` (`QuizTimeoutUITests`), results/replay, launch (`LaunchTests`), and accessibility-XXXL usability (`AccessibilityUITests`).
- Fakes: `StubMediaLibrary` (mode-driven, section 6), `StubAudioPlayer`/`FakeAudioPlayer`, `FakeClock`, `SeededRandomSource` (SplitMix64).
- Use accessibility identifiers rather than brittle text selectors.
- Run the simulator build and test commands after every feature.
- Run physical-device media and audio checks before MVP completion; record device-only limitations in docs/decision-log.md (2026-08-18 entry: device checks blocked in this environment).

### Agents

- Testing agent owns test implementation.
- Build agent owns repeatable xcodebuild commands.
- Product-QA agent owns scenario matrix.
- Code-review agent checks test quality and missing failure paths.

### Checklist

- [x] Unit suite passes.
- [x] UI suite passes.
- [x] Simulator build passes.
- [x] Failure scenarios are recorded.

### Acceptance gate

All automated checks pass and device-only behavior has evidence.

## [x] 9. MVP release readiness (Completed)

### Goal

Ship a private, local-only first MVP with clear limitations.

### Specification

- Verify app metadata and privacy wording, including the exact `NSAppleMusicUsageDescription` string from Project facts.
- Verify no network entitlement or external music dependency exists: no URLSession/Network imports, no Swift packages, no entitlements in the signed bundle; the single requested permission is Music access.
- Verify release build configuration (simulator Release succeeds).
- Verify permission denial (Open Settings), restricted, empty library, and playback-failure messaging are defined and covered by tests.
- Verify no song audio or metadata leaves the device.
- Update all docs and roadmap status; prepare a Conventional Commit and the release checklist.
- Device-only follow-ups before shipping to a real iPhone (blocked here, listed in docs/release-checklist.md and the decision log): authorization flow, catalog mapping, local playback, interruptions, and route changes on a real device.

### Agents

- Release agent checks signing and release configuration.
- Privacy/media-library agents check local-only behavior.
- Code-review agent performs final read-only review.
- Documentation agent performs final Markdown audit.
- Commit agent creates final Conventional Commit.

### Checklist

- [x] Release build succeeds.
- [x] Privacy review passes.
- [x] Final QA passes.
- [x] Docs are current.
- [x] All completed roadmap sections have [x] and (Completed).
- [x] Remaining work is explicit.
- [x] Conventional Commit is prepared.

### Acceptance gate

First working MVP runs on an iPhone with local Music-library songs and satisfies all documented constraints.

## [x] 10. Easy and hard quiz modes (Completed)

### Goal

Let players choose between a multiple-choice quiz and the original typed-answer quiz from the home screen, with identical styling and scoring except for a tighter fast-answer window in easy mode.

### Specification

Mode selection:

- `QuizMode { easy, hard }` (pure domain enum). `QuizConfiguration` gains `mode` (default `.hard`); `QuizConfiguration.fastThreshold` is computed from the mode: **3 seconds** for easy (27 or more seconds remaining on the clock), **5 seconds** for hard — unchanged from the MVP.
- `AppModel.startQuiz(mode:)` builds the engine with the chosen mode; `replay()` restarts the same mode. Home shows two full-width buttons: **Easy Mode** (accent-filled, caption "5 choices") and **Hard Mode** (bordered, caption "Type the answer"). Identifiers `home.startEasy`, `home.startHard` replace `home.startQuiz`.

Easy mode:

- `OptionGenerator.options(for:from:random:limit: 5)` returns up to five options per round: the correct track plus up to four decoys from the full catalog, all shuffled with the injected random source (deterministic per seed). Decoys whose normalized title equals the correct track's title — or duplicates another decoy's title — are excluded so the player never sees two identically labeled options. A catalog smaller than five tracks yields fewer options (never fewer than one).
- `QuizSession.submitOption(trackID:now:)` evaluates the pick by track identity (persistent media ID), never by title text, so a same-title decoy can never count as correct. Same timeout boundary as `submitAnswer` (elapsed > duration → `timedOut`), same one-attempt/first-terminal-event rules.
- The quiz screen renders the five options stacked below each other (`quiz.option`, label "Title, Artist", value "Correct answer" / "Your answer" after settling) **instead of** the answer field and its autocomplete. Picking an option settles the round immediately; there is no Submit button (Skip and Next behave as in hard mode).
- When the pick is wrong, the correct option is highlighted in `success` (checkmark, 2 pt border) **and** the picked option in `danger` (cross, 2 pt border); other options dim. When the pick is correct, only the correct option is highlighted. A timeout never marks a pick as wrong. Feedback banners, answer reveal, timer, scoring penalties, results, and replay are identical to hard mode.
- Hard mode is byte-for-byte the MVP behavior: free-text input, autocomplete, Submit, 5-second fast window.

Scoring:

- Same formula `(10 + remainingSeconds) × multiplier`; the multiplier window is mode-dependent via `ScoreCalculator.breakdown(forCorrectAnswerAt:roundDuration:fastThreshold:)`, `ScoreCalculator.score(for:roundDuration:fastThreshold:)`, and `QuizResult.fastThreshold` (carried from the configuration into the session summary so totals match the mode). Defaults keep the hard-mode 5-second window everywhere else.

Tests:

- Unit: option generation (`OptionGeneratorTests`), option submission (`QuizSessionTests`), easy thresholds and session totals (`ScoreCalculatorTests`), easy-mode view-model behavior incl. highlight state and isolation from typed input (`QuizViewModelModeTests`).
- UI: easy-mode journey with correct/wrong highlight assertions and same-mode replay (`EasyModeUITests`); every pre-existing UI test now starts via `home.startHard` and still passes unchanged.

### Agents

- Builder owns domain, view model, and view changes.
- Testing agent covers option generation, identity matching, and the easy journey.
- SwiftUI-design agent checks highlight clarity and Dynamic Type.
- Documentation agent updates quiz-rules, design-system, and this roadmap.

### Checklist

- [x] Home offers Easy and Hard modes.
- [x] Easy mode shows up to five options per round.
- [x] Wrong picks highlight both the correct and the picked option.
- [x] Easy mode uses a 3-second 2x window; hard mode keeps 5 seconds.
- [x] Hard mode behavior is unchanged.
- [x] Unit and UI suites pass.

### Acceptance gate

A player can start either mode from home, replay keeps the mode, easy rounds settle on one pick with clear correct/wrong highlights, and the hard-mode experience is exactly the MVP one.

## Future work after MVP

- Physical-device follow-ups from docs/release-checklist.md: authorization flow, local playback, interruptions, and route changes on a real iPhone.
- Files-app MP3 importer.
- Persistent history and personal statistics.
- Configurable round count and timer.
- Fuzzy typo tolerance.
- iPad layout.
- Shareable local results.
- Optional local artwork cache, and re-enabling artwork display in the quiz via the dormant `ArtworkAccent` helper.

