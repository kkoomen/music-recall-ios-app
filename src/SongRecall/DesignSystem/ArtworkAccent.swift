import SwiftUI
import UIKit

/// Decoration helper that derives an accent color from album artwork.
/// Used only behind surfaces — text always stays on semantic colors.
enum ArtworkAccent {
    /// Average color of the artwork image data.
    static func color(from data: Data) -> Color? {
        guard let image = UIImage(data: data) else { return nil }
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard
            let cgImage = rendered.cgImage,
            let provider = cgImage.dataProvider,
            let pixelData = provider.data,
            let bytes = CFDataGetBytePtr(pixelData)
        else { return nil }
        // RGBA byte order in this context.
        let red = Double(bytes[0]) / 255
        let green = Double(bytes[1]) / 255
        let blue = Double(bytes[2]) / 255
        return Color(red: red, green: green, blue: blue)
    }
}
