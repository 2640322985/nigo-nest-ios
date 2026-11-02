import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var nav = AppNav()
    @State private var tab = 0

    var body: some View {
        Group {
            if session.user == nil {
                LoginView()
            } else {
                NavigationStack(path: $nav.path) {
                    TabView(selection: $tab) {
                        Tab("广场", systemImage: "bubble.left.and.bubble.right", value: 0) {
                            PlazaView()
                        }
                        Tab("我的", systemImage: "person", value: 1) {
                            ProfileView()
                        }
                    }
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
                .environmentObject(nav)
            }
        }
        .background(Palette.paper)
    }
}
