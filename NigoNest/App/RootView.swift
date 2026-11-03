import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var tab = 0

    init(initialTab: Int = 0) { _tab = State(initialValue: initialTab) }

    var body: some View {
        Group {
            if session.user == nil {
                LoginView()
            } else {
                    TabView(selection: $tab) {
                        Tab("今日", systemImage: "sun.max", value: 0) {
                            CampusNavigation { TodayView() }
                        }
                        Tab("广场", systemImage: "bubble.left.and.bubble.right", value: 1) {
                            CampusNavigation { PlazaView() }
                        }
                        Tab("消息", systemImage: "tray", value: 2) {
                            CampusNavigation { MessageHubView() }
                        }
                        Tab("我的", systemImage: "person", value: 3) {
                            CampusNavigation { ProfileView() }
                        }
                    }
                }
        }
        .background(Palette.paper)
    }
}

extension View {
    func routeDestinations() -> some View {
        self.modifier(RouteDestinations())
    }
}

struct CampusNavigation<Content: View>: View {
    @StateObject private var nav = AppNav()
    @ViewBuilder var content: () -> Content
    var body: some View {
        NavigationStack(path: $nav.path) { content().routeDestinations() }
            .environmentObject(nav)
    }
}

private struct RouteDestinations: ViewModifier {
    @EnvironmentObject private var nav: AppNav
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .schedule: ScheduleView()
                        case .classroom: ClassroomView()
                        case .venue: VenueView()
                        case .orders: VenueOrdersView()
                        case .buddies: BuddiesView()
                        case .grab: CourseGrabView()
                        case .yx: YxExamView()
                        case .safety: SafetyExamView()
                        case .friends: FriendsView()
                        case .chat(let id, let name, let avatar): ChatView(studentId: id, nickname: name, avatarUrl: avatar)
                        case .user(let id): UserProfileView(studentId: id)
                        case .notifications: NotificationsView()
                        case .suggestions: SuggestionsView()
                        case .checkin: CheckinView()
                        case .leaderboard: LeaderboardView()
                        case .compose: ComposeView()
                        case .mine: MyContentView()
                        case .account: AccountView()
                        case .post(let id): PostDetailView(postId: id)
                        }
                    }
    }
}
