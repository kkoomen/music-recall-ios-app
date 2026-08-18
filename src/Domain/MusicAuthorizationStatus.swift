import Foundation

/// Authorization state for the user's Music library.
enum MusicAuthorizationStatus: Equatable, Hashable, Sendable {
    case notDetermined
    case denied
    case restricted
    case authorized
}
