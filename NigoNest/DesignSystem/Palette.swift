import SwiftUI

enum Palette {
    static let ink = Color.primary
    static let paper = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let rule = Color.primary.opacity(0.13)
    static let course = [
        Color.primary, Color.secondary, Color.primary, Color.secondary,
    ]
}

enum InkFont {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size)
    }
}
