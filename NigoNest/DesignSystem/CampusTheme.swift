import SwiftUI

private struct CampusThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.monochrome
}

extension EnvironmentValues {
    var campusTheme: AppTheme {
        get { self[CampusThemeKey.self] }
        set { self[CampusThemeKey.self] = newValue }
    }
}

@propertyWrapper
struct ThemePalette: DynamicProperty {
    @Environment(\.campusTheme) private var theme
    @Environment(\.colorScheme) private var scheme
    var wrappedValue: CampusColors { CampusColors(theme: theme, scheme: scheme) }
}

struct CampusColors {
    var theme: AppTheme
    var scheme: ColorScheme
    var isJournal: Bool { theme == .journal }
    private var dark: Bool { scheme == .dark }
    private func rgb(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
    var ink: Color { isJournal ? rgb(dark ? 0xF2E7D9 : 0x292521) : .primary }
    var paper: Color { isJournal ? rgb(dark ? 0x211E1B : 0xFBF6ED) : Color(uiColor: .systemBackground) }
    var surface: Color { isJournal ? rgb(dark ? 0x302A25 : 0xFFFCF7) : Color(uiColor: .secondarySystemBackground) }
    var note: Color { isJournal ? rgb(dark ? 0x3B3023 : 0xFFF0C9) : paper }
    var rule: Color { ink.opacity(isJournal ? 0.19 : 0.13) }
    var accent: Color { isJournal ? rgb(dark ? 0xF1A190 : 0xAC3834) : ink }
    var onAccent: Color { isJournal ? (dark ? rgb(0x241916) : .white) : paper }
    var blue: Color { isJournal ? rgb(dark ? 0x9CBFE9 : 0x345F98) : ink }
    var course: [Color] { isJournal ? [blue, accent, blue, accent] : [.primary, .secondary, .primary, .secondary] }
}

struct ThemeHost<Content: View>: View {
    @AppStorage(ThemePreference.key) private var savedTheme = AppTheme.monochrome.rawValue
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: () -> Content
    private var active: AppTheme {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-previewTheme"), args.count > index + 1 {
            return AppTheme.resolve(args[index + 1])
        }
        #endif
        return AppTheme.resolve(savedTheme)
    }
    var body: some View {
        let colors = CampusColors(theme: active, scheme: scheme)
        content().environment(\.campusTheme, active)
            .tint(colors.accent).foregroundStyle(colors.ink)
    }
}

struct ThemePaper: View {
    @ThemePalette private var palette
    var body: some View {
        palette.paper.overlay {
            if palette.isJournal {
                Canvas { context, size in
                    // Fixed, subtle grain; never randomizes as the page redraws.
                    for row in 0..<Int(size.height / 7) {
                        for column in 0..<Int(size.width / 7) {
                            let x = CGFloat(column * 7 + (row * 3 % 5))
                            let y = CGFloat(row * 7 + (column * 2 % 5))
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.8, height: 0.8)), with: .color(palette.ink.opacity(0.055)))
                        }
                    }
                }.accessibilityHidden(true)
            }
        }.ignoresSafeArea()
    }
}

struct JournalCampusBanner: View {
    @ThemePalette private var palette
    var body: some View {
        if palette.isJournal {
            Image("JournalCampus").renderingMode(palette.scheme == .dark ? .template : .original)
                .resizable().scaledToFit().foregroundStyle(palette.blue).frame(maxHeight: 80)
                .opacity(0.85).frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
    }
}

struct NotebookLines: View {
    @ThemePalette private var palette
    var body: some View {
        Canvas { context, size in
            for y in stride(from: CGFloat(27), to: size.height, by: 27) {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(palette.blue.opacity(0.12)), lineWidth: 0.6)
            }
        }.accessibilityHidden(true)
    }
}

struct JournalTape: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1).fill(Color(red: 0.78, green: 0.3, blue: 0.26).opacity(0.32))
            .frame(width: 32, height: 12).rotationEffect(.degrees(-16))
            .padding(.leading, 14).offset(y: -4).accessibilityHidden(true)
    }
}

extension View {
    func journalPostSurface() -> some View { modifier(JournalPostSurface()) }
}

private struct JournalPostSurface: ViewModifier {
    @ThemePalette private var palette
    @ViewBuilder func body(content: Content) -> some View {
        if palette.isJournal {
            content.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(palette.rule, lineWidth: 0.75))
        } else { content }
    }
}
