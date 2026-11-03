import SwiftUI

struct MessageHubView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var session: SessionStore
    @State private var friendUnread = 0
    @State private var notificationUnread = 0
    @State private var friends: [(id: String, name: String, avatar: String?, preview: String)] = []
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
                if !friends.isEmpty {
                    CampusSection(title: "最近聊天")
                    ForEach(friends, id: \.id) { friend in
                        Button {
                            nav.open(.chat(friend.id, friend.name, friend.avatar ?? ""))
                        } label: {
                            HStack(spacing: 12) {
                                InkAvatar(url: friend.avatar, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name).font(.body)
                                    if !friend.preview.isEmpty {
                                        Text(friend.preview).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                Spacer()
                            }.foregroundStyle(palette.ink)
                        }.buttonStyle(.plain)
                    }
                }
                CampusArtwork(name: "CampusReading").frame(height: 180).frame(maxWidth: .infinity)
            }.padding(20)
        }.background(ThemePaper())
            .navigationTitle("消息").navigationBarTitleDisplayMode(.inline)
            .task {
                if let data = try? await session.client.get("api/friends") {
                    let object = JSON.object(data)
                    friendUnread = JSON.int(object["unreadCount"])
                    friends = JSON.dictionaries(object["friends"]).map { row in
                        let avatar = JSON.string(row["avatarUrl"])
                        return (
                            JSON.string(row["studentId"]),
                            JSON.string(row["nickname"], fallback: "同学"),
                            avatar.hasPrefix("http") ? avatar : nil,
                            JSON.string(row["lastMessage"])
                        )
                    }
                }
                if let data = try? await session.client.get("api/notifications/unread-count") {
                    notificationUnread = JSON.int(JSON.object(data)["unreadCount"])
                }
            }
    }
}
