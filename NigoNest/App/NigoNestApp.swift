import SwiftUI

@main
struct NigoNestApp: App {
    @StateObject private var session = SessionStore()

    private var previewRoot: some View {
        let args = ProcessInfo.processInfo.arguments
        if let flag = args.firstIndex(of: "-preview"), args.count > flag + 1 {
            return AnyView(PreviewHost(page: args[flag + 1]))
        }
        return AnyView(RootView().environmentObject(session))
    }

    var body: some Scene {
        WindowGroup {
            previewRoot
                .preferredColorScheme(.light)
        }
    }
}
