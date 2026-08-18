# Source Structure

`src/` mirrors the layout of the sibling `zihe` project: the app source folder, the Xcode project, and the test folders are siblings.

```
src/
  SongRecall.xcodeproj/   Xcode project (source root = src/)
  SongRecall/             app target source (file-system-synchronized)
    App/                  app entry point and composition root
    Domain/               pure models, quiz state, answer matching, scoring, rules
    Services/             MediaPlayer, AVFoundation, timing, randomness, system integration
    Features/Home/        library status and start action
    Features/Permission/  authorization and empty-library states
    Features/Quiz/        quiz session and answer interaction
    Features/Results/     completed-session summary and replay
    DesignSystem/         colors, typography, spacing, components, motion
    Resources/            local app assets and configuration resources
  SongRecallTests/        unit-test target source (including Fixtures/)
  SongRecallUITests/      UI-test target source
```

## Project mapping

- `SongRecall/` feeds the `SongRecall` app target.
- `SongRecallTests/` (including its `Fixtures/` subfolder) feeds the `SongRecallTests` unit-test target.
- `SongRecallUITests/` feeds the `SongRecallUITests` UI-test target.

The project uses file-system-synchronized groups: adding or removing files inside those folders is picked up automatically; no project-file edits are needed.
