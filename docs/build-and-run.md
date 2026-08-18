# Build and Run

## Local setup

Install Xcode 26 or later. Open `SongRecall.xcodeproj` at the repository root. Select the `SongRecall` scheme and an iOS 26 simulator (for example `iPhone 17`) or a connected iPhone.

The project uses file-system-synchronized folders:

- `src/` feeds the `SongRecall` app target.
- `tests/Unit/` and `tests/Fixtures/` feed the `SongRecallTests` unit-test target.
- `tests/UI/` feeds the `SongRecallUITests` UI-test target.

Adding or removing files inside those folders is picked up automatically; no project-file edits are needed.

## Simulator

Use the simulator for SwiftUI layout, domain behavior, permission-state mocks, and UI tests. The simulator cannot represent a personal Music library reliably.

Build:

```sh
xcodebuild \
  -project src/SongRecall.xcodeproj \
  -scheme SongRecall \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedData \
  build
```

Test (unit and UI):

```sh
xcodebuild \
  -project src/SongRecall.xcodeproj \
  -scheme SongRecall \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build/DerivedData \
  test
```

`-derivedDataPath .build/DerivedData` keeps build artifacts inside the ignored `.build/` directory.

## Physical device

Use a signed development build on an iPhone for MediaPlayer authorization and local audio verification. Add local playable tracks to the Music library before testing.

Device builds require a development team and signing identity configured for the `SongRecall` target in Xcode.

## Build expectations

Build agent must run a clean simulator build and test command after feature work. It must report destination, scheme, command, result, and first decisive failure line.

## Build constraints

- No network dependency.
- No third-party package resolution.
- No hidden generated source.
- No build warnings introduced without documentation.
