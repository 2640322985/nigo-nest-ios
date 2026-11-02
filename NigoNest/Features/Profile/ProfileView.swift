import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                InkTitle(text: "我的", size: 34)
                HStack(alignment: .center, spacing: 14) {
                    InkAvatar(url: session.user?.avatarUrl, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.user?.nickname ?? "同学")
                            .font(InkFont.title(20))
                        Text(session.user?.studentId ?? "")
                            .font(InkFont.body(14))
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 4)
                WavyDivider()
                InkRow(title: "账号") { nav.open(.account) }
                InkRow(title: "签到") { nav.open(.checkin) }
                InkRow(title: "积分排行榜") { nav.open(.leaderboard) }
                WavyDivider()
                InkRow(title: "课表") { nav.open(.schedule) }
                InkRow(title: "空教室") { nav.open(.classroom) }
                InkRow(title: "场馆预约") { nav.open(.venue) }
                InkRow(title: "抢课") { nav.open(.grab) }
                InkRow(title: "迎新答题") { nav.open(.yx) }
                InkRow(title: "安全考试") { nav.open(.safety) }
                WavyDivider()
                InkRow(title: "好友") { nav.open(.friends) }
                InkRow(title: "消息") { nav.open(.notifications) }
                InkRow(title: "我的动态") { nav.open(.mine) }
                InkRow(title: "发帖") { nav.open(.compose) }
                WavyDivider()
                InkRow(title: "功能建议") { nav.open(.suggestions) }
                Button("退出登录") {
                    session.logout()
                }
                .officialAction(prominent: false)
                .padding(.top, 16)
            }
            .padding(24)
        }
        .background(Palette.paper)
    }
}
