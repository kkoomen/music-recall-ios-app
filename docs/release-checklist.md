# Release Checklist

## Product

- [x] First launch is understandable.
- [x] Permission denial is recoverable (Open Settings path).
- [x] Empty library has useful guidance.
- [x] Ten-round quiz completes.
- [x] Results and replay work.

## Technical

- [x] iOS 26 deployment target verified.
- [x] Release build succeeds (simulator Release configuration).
- [x] Unit and UI tests pass (60 unit, 8 UI).
- [ ] Device audio test passes (blocked — see docs/decision-log.md).
- [x] No third-party dependencies.
- [x] No external music or network service.

## Accessibility

- [x] VoiceOver flow works (meaningful labels; answer not leaked).
- [x] Dynamic Type does not clip (ViewThatFits + accessibility-XXXL UI test).
- [x] Reduce Motion is respected (transitions and haptics gated).
- [x] Contrast and touch targets pass (48pt minimums; accent text ≈9:1).

## Privacy

- [x] Music usage description is accurate.
- [x] No song data leaves device (no network imports, no entitlements).
- [x] No unnecessary permission exists (single NSAppleMusicUsageDescription).

## Documentation

- [x] ROADMAP reflects reality.
- [x] All completed sections end with (Completed).
- [x] Remaining work is explicit.
- [x] Decision log contains device limitations.

## Device-only follow-ups before shipping to a real iPhone

- Run a signed development build on an iPhone.
- Verify MediaPlayer authorization flow and catalog mapping against a real Music library.
- Verify local audio playback, interruptions, and route changes on speakers and headphones.
- Record results in docs/decision-log.md and flip the two blocked ROADMAP checklist items.
