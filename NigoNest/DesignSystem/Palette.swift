import SwiftUI

enum InkFont {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size)
    }
}
