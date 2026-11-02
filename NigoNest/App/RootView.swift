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
                    VStack(spacing: 0) {
                        Group {
                            if tab == 0 {
                                PlazaView()
                            } else {
                                ProfileView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        HStack {
                            tabButton("广场", index: 0)
                            tabButton("我的", index: 1)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .background(Palette.paper)
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
                        case .chat(let id, let name): ChatView(studentId: id, nickname: name)
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

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            tab = index
        } label: {
            Text(title)
                .font(index == tab ? InkFont.title(20) : InkFont.body())
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
