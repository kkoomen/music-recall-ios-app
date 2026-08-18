# Privacy

## Data boundary

Song Recall operates on-device. It reads metadata and playable local assets from the authorized Music library for the active quiz. It does not upload audio, metadata, guesses, scores, or identifiers.

## Permissions

Request only Music library permission. Explain purpose in user-facing text. Handle denial without repeated prompts.

## Dependencies

Do not add analytics, advertising, authentication, remote metadata, recognition, streaming, or external music APIs.

## Review

Privacy review checks source imports, entitlements, Info.plist descriptions, network usage, logging, crash output, and release settings.
