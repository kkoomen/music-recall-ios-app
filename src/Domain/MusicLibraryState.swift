import Foundation

/// User-visible state of the local music library catalog.
///
/// - `loading`: catalog fetch in progress.
/// - `notDetermined`: permission has not been requested yet.
/// - `denied`: user denied access; Settings guidance applies.
/// - `restricted`: access cannot be changed inside the app.
/// - `empty`: authorized, but no playable local tracks exist.
/// - `ready`: authorized with a playable track catalog.
enum MusicLibraryState: Equatable, Sendable {
    case loading
    case notDetermined
    case denied
    case restricted
    case empty
    case ready([Track])
}
