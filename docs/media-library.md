# Media Library

## Source

Use Apple's MediaPlayer framework. Query the user's Music library. Do not call external music services or network catalog APIs.

## Authorization

Request authorization only when the app needs library data. Explain that access is required to find and play songs stored locally in the user's Music library.

Add a clear NSAppleMusicUsageDescription. Never imply that the app uploads music or shares library information.

Handle not determined, authorized, denied, and restricted states. Denied state offers a Settings path. Restricted state explains that access cannot be changed inside the app.

## Local track filtering

Query songs, then keep only records with a usable local asset URL. Exclude cloud-only, DRM-protected, missing, or unsupported assets. Treat a missing asset URL as normal library data, not an app crash.

Map persistent media identifier, title, artist, album, artwork, and asset URL into the domain Track type. Preserve stable identity for duplicate titles.

## Important boundary

MediaPlayer reads the iPhone Music library. It does not expose arbitrary MP3 files sitting in Files.app. A future Files importer must be a separate feature with its own security, storage, and test design.

## Implementation

Concrete types:

- `Domain/Track`: pure value type with a `UInt64` id backed by the persistent media identifier, title, artist, album, and local `assetURL`.
- `Domain/MusicAuthorizationStatus`: `notDetermined`, `denied`, `restricted`, `authorized`.
- `Domain/MusicLibraryState`: `loading`, `notDetermined`, `denied`, `restricted`, `empty`, `ready([Track])`.
- `Services/MediaItemRecord`: plain projection of `MPMediaItem` used so mapping stays testable.
- `Services/TrackMapper`: pure filtering; keeps records with a non-nil `assetURL` that are not DRM-protected.
- `Services/MediaLibraryProviding`: injectable main-actor protocol (status, request, catalog fetch, lazy artwork).
- `Services/MediaLibraryService`: `MPMediaPlayer` adapter; caches items after a fetch and extracts JPEG artwork on demand per quiz round so the catalog never holds every artwork in memory.

Artwork is deliberately not stored inside `Track`. The service exposes `artworkData(for:)` so a single round fetches only the artwork it displays.

## Testing

Unit tests use fake MediaLibraryProviding data. Device tests use a real iPhone with local, playable MP3 files. Simulator tests must not depend on a real Music library.
