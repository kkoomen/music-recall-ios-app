# Source Structure

`SongRecall.xcodeproj` lives in this directory. Its file-system-synchronized groups map:

- `App`, `Domain`, `Services`, `Features`, `DesignSystem`, `Resources` to the `SongRecall` app target.
- `../tests/Unit` and `../tests/Fixtures` to the `SongRecallTests` unit-test target.
- `../tests/UI` to the `SongRecallUITests` UI-test target.

Ownership:

- App: app entry point and composition root.
- Domain: pure models, quiz state, answer matching, scoring, and rules.
- Services: MediaPlayer, AVFoundation, timing, randomness, and system integration.
- Features/Home: library status and start action.
- Features/Permission: authorization and empty-library states.
- Features/Quiz: quiz session and answer interaction.
- Features/Results: completed-session summary and replay.
- DesignSystem: colors, typography, spacing, components, and motion.
- Resources: local app assets and configuration resources.
