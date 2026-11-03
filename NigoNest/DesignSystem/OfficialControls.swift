import SwiftUI

extension View {
    func officialAction(prominent: Bool = true) -> some View {
        modifier(OfficialActionStyle(prominent: prominent))
    }
}

private struct OfficialActionStyle: ViewModifier {
    var prominent: Bool
    @ThemePalette private var palette
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                content.buttonStyle(.glassProminent).controlSize(.large).foregroundStyle(palette.onAccent)
            } else {
                content.buttonStyle(.glass).controlSize(.large)
            }
        } else if prominent {
            content.buttonStyle(.borderedProminent).controlSize(.large).foregroundStyle(palette.onAccent)
        } else {
            content.buttonStyle(.bordered).controlSize(.large)
        }
    }
}
