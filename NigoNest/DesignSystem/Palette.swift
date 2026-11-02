import SwiftUI

enum Palette {
    static let ink = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let paper = Color.white
    static let course = [
        Color(red: 0.93, green: 0.45, blue: 0.38),
        Color(red: 0.29, green: 0.56, blue: 0.85),
        Color(red: 0.36, green: 0.68, blue: 0.48),
        Color(red: 0.86, green: 0.62, blue: 0.28),
    ]
}

enum InkFont {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}
