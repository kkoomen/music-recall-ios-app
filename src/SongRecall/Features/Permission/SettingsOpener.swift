import UIKit

/// Opens the system Settings app for the Song Recall permission.
enum SettingsOpener {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
