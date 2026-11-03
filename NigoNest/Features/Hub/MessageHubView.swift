import SwiftUI

struct MessageHubView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var session: SessionStore
    @State private var friendUnread = 0
    @State private var notificationUnread = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                InkTitle(text: "有消息，慢慢聊。", size: 30)
                Text("同学的问候，校园的新动态。").font(.subheadline).foregroundStyle(.secondary)
                CampusGroup {
                    CampusLink(title: "好友与聊天", icon: "bubble.left.and.bubble.right", badge: friendUnread) { nav.open(.friends) }
                    Divider()
                    CampusLink(title: "通知与互动", icon: "bell", badge: notificationUnread) { nav.open(.notifications) }
                }
                Text("好友申请在「好友与聊天」中处理；点赞、评论和任务进度在通知中查看。")
                    .font(.footnote).foregroundStyle(.secondary)
                CampusArtwork(name: "CampusReading").frame(height: 180).frame(maxWidth: .infinity)
            }.padding(20)
        }.background(ThemePaper())
            .navigationTitle("消息").navigationBarTitleDisplayMode(.inline)
            .task {
                if let data = try? await session.client.get("api/friends/unread-count") {
                    friendUnread = JSON.int(JSON.object(data)["unreadCount"])
                }
                if let data = try? await session.client.get("api/notifications/unread-count") {
                    notificationUnread = JSON.int(JSON.object(data)["unreadCount"])
                }
            }
    }
}
