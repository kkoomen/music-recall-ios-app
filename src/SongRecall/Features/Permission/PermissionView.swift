import SwiftUI

/// Explains Music access, handles denial, restricted access, and the
/// empty-library state.
struct PermissionView: View {
    let state: MusicLibraryState
    let onRequestAccess: () -> Void
    let onOpenSettings: () -> Void

    private var isPermissionPrompt: Bool { state == .notDetermined }
    private var isDenied: Bool { state == .denied }
    private var isRestricted: Bool { state == .restricted }
    private var isEmpty: Bool { state == .empty }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier(AccessibilityID.permissionTitle)

            Text(message)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()

            if isPermissionPrompt {
                Button(action: onRequestAccess) {
                    Text("Allow Music Access")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.accentText)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.permissionAllow)
            }

            if isDenied {
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.accentText)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTouchHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .accessibilityIdentifier(AccessibilityID.permissionSettings)
            }
        }
        .padding(24)
    }

    private var iconName: String {
        switch state {
        case .notDetermined: return "music.note"
        case .denied: return "lock.fill"
        case .restricted: return "exclamationmark.shield.fill"
        case .empty: return "tray"
        default: return "music.note"
        }
    }

    private var title: String {
        switch state {
        case .notDetermined: return "Your music stays on your iPhone"
        case .denied: return "Music access is turned off"
        case .restricted: return "Music access is restricted"
        case .empty: return "No local songs found"
        default: return ""
        }
    }

    private var message: String {
        switch state {
        case .notDetermined:
            return "Song Recall plays songs already stored in your Music library. "
                + "Nothing ever leaves your device — no uploads, no analytics."
        case .denied:
            return "Song Recall needs Music access to find and play songs stored locally. "
                + "You can change this anytime in Settings."
        case .restricted:
            return "Music access is managed by a restriction on this device and "
                + "cannot be changed inside Song Recall."
        case .empty:
            return "No locally playable songs were found. Add songs to your Music library "
                + "on this iPhone — download them so they are stored on the device — then try again."
        default:
            return ""
        }
    }
}

#Preview("Not determined") {
    PermissionView(
        state: .notDetermined,
        onRequestAccess: {},
        onOpenSettings: {}
    )
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Denied") {
    PermissionView(
        state: .denied,
        onRequestAccess: {},
        onOpenSettings: {}
    )
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
