# Build and Run

## Local setup

Install Xcode 26 or later. Open the Song Recall project. Select the SongRecall scheme and an iOS 26 simulator or connected iPhone.

## Simulator

Use simulator for SwiftUI layout, domain behavior, permission-state mocks, and UI tests. Simulator cannot represent a personal Music library reliably.

## Physical device

Use a signed development build on an iPhone for MediaPlayer authorization and local audio verification. Add local playable tracks to the Music library before testing.

## Build expectations

Build agent must run a clean simulator build and test command after feature work. It must report destination, scheme, command, result, and first decisive failure line.

## Build constraints

- No network dependency.
- No third-party package resolution.
- No hidden generated source.
- No build warnings introduced without documentation.
