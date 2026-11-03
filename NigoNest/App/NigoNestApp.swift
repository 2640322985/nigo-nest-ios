import SwiftUI

@main
struct NigoNestApp: App {
    @StateObject private var session = SessionStore()

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-persistTheme"), args.count > index + 1,
           let theme = AppTheme(rawValue: args[index + 1]) {
            ThemePreference.save(theme)
        }
        #endif
    }

    private var previewRoot: some View {
        let args = ProcessInfo.processInfo.arguments
        #if DEBUG
        if let flag = args.firstIndex(of: "-preview"), args.count > flag + 1 {
            return AnyView(PreviewHost(page: args[flag + 1]))
        }
        #endif
        return AnyView(RootView().environmentObject(session))
    }

    private var previewAppearance: ColorScheme? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-previewAppearance"), args.count > index + 1 {
            return args[index + 1] == "dark" ? .dark : .light
        }
        #endif
        return nil
    }

    var body: some Scene {
        WindowGroup {
            ThemeHost { previewRoot }
                .preferredColorScheme(previewAppearance)
        }
    }
}
