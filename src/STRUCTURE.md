# Source Structure

No Swift implementation exists yet. This directory defines intended ownership.

- App: app entry point and composition root.
- Domain: pure models, quiz state, answer matching, scoring, and rules.
- Services: MediaPlayer, AVFoundation, timing, randomness, and system integration.
- Features/Home: library status and start action.
- Features/Permission: authorization and empty-library states.
- Features/Quiz: quiz session and answer interaction.
- Features/Results: completed-session summary and replay.
- DesignSystem: colors, typography, spacing, components, and motion.
- Resources: local app assets and configuration resources.
