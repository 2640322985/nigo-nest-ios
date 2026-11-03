import SwiftUI

private struct Person: Identifiable {
    var id: String
    var name: String
    var avatar: String?
    var detail: String
    var unread: Int
}

struct FriendsView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var friends: [Person] = []
    @State private var incoming: [Person] = []
    @State private var target = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "好友") {
            TextField("对方学号", text: $target).inkField()
            InkButton(title: "加好友") { Task { await requestFriend() } }
            StatusText(text: error)
            if !incoming.isEmpty {
                Text("收到的申请").font(InkFont.title(18))
                ForEach(incoming) { item in
                    HStack(spacing: 12) {
                        InkAvatar(url: item.avatar, size: 40)
                        Text(item.name).font(InkFont.body())
                        Spacer()
                        Button("同意") { Task { await accept(item.id) } }
                        Button("拒绝") { Task { await reject(item.id) } }
                    }
                    .foregroundStyle(palette.ink)
                }
                WavyDivider()
            }
            if friends.isEmpty {
                Text("还没有好友。可以在广场点头像添加。").font(InkFont.body(14))
            }
            ForEach(friends) { item in
                Button {
                    nav.open(.chat(item.id, item.name, item.avatar ?? ""))
                } label: {
                    HStack(spacing: 12) {
                        InkAvatar(url: item.avatar, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(InkFont.body())
                            if !item.detail.isEmpty {
                                Text(item.detail).font(InkFont.body(13)).lineLimit(1)
                            }
                        }
                        Spacer()
                        if item.unread > 0 {
                            Text("\(item.unread)")
                                .font(InkFont.body(12))
                                .foregroundStyle(palette.paper)
                                .padding(.horizontal, 6)
                                .background(palette.ink, in: Capsule())
                        }
                    }
                    .foregroundStyle(palette.ink)
                }
                .buttonStyle(.plain)
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/friends"))
            friends = JSON.dictionaries(data["friends"]).map { row in
                let avatar = JSON.string(row["avatarUrl"])
                return Person(
                    id: JSON.string(row["studentId"]),
                    name: JSON.string(row["nickname"], fallback: "同学"),
                    avatar: avatar.hasPrefix("http") ? avatar : nil,
                    detail: JSON.string(row["lastMessage"]),
                    unread: JSON.int(row["unreadCount"])
                )
            }
            incoming = JSON.dictionaries(data["incoming"]).map { row in
                let avatar = JSON.string(row["avatarUrl"])
                return Person(
                    id: JSON.string(row["studentId"]),
                    name: JSON.string(row["nickname"], fallback: "同学"),
                    avatar: avatar.hasPrefix("http") ? avatar : nil,
                    detail: "",
                    unread: 0
                )
            }
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func requestFriend() async {
        do {
            _ = try await session.client.post("api/friends/request", json: [
                "authToken": session.user?.token ?? "",
                "targetStudentId": target.trimmingCharacters(in: .whitespaces),
            ])
            target = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func accept(_ id: String) async {
        do {
            _ = try await session.client.post("api/friends/accept", json: ["authToken": session.user?.token ?? "", "studentId": id])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func reject(_ id: String) async {
        do {
            _ = try await session.client.post("api/friends/reject", json: ["authToken": session.user?.token ?? "", "studentId": id])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct UserProfileView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    var studentId: String
    @State private var name = ""
    @State private var avatar: String?
    @State private var status = ""
    @State private var grade = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "同学") {
            HStack(spacing: 14) {
                InkAvatar(url: avatar, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "同学" : name).font(InkFont.title(22))
                    Text(studentId).font(InkFont.body(14))
                    if !grade.isEmpty { Text(grade).font(InkFont.body(14)) }
                }
            }
            StatusText(text: error)
            if status == "friends" {
                InkButton(title: "发消息") { nav.open(.chat(studentId, name, avatar ?? "")) }
            } else if status == "pending_sent" {
                Text("已发送好友申请").font(InkFont.body())
            } else if status == "pending_received" {
                InkButton(title: "同意好友") { Task { await accept() } }
            } else if status != "self" {
                InkButton(title: "加好友") { Task { await request() } }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/users/\(studentId)/profile"))
            let profile = data["profile"] as? [String: Any] ?? [:]
            name = JSON.string(profile["nickname"], fallback: "同学")
            let raw = JSON.string(profile["avatarUrl"])
            avatar = raw.hasPrefix("http") ? raw : nil
            status = JSON.string(profile["friendStatus"])
            grade = JSON.string(profile["grade"])
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func request() async {
        do {
            _ = try await session.client.post("api/friends/request", json: [
                "authToken": session.user?.token ?? "",
                "targetStudentId": studentId,
            ])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func accept() async {
        do {
            _ = try await session.client.post("api/friends/accept", json: ["authToken": session.user?.token ?? "", "studentId": studentId])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct ChatLine: Identifiable {
    var id: Int
    var mine: Bool
    var text: String
}

struct ChatView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    var studentId: String
    var nickname: String
    var avatarUrl: String
    @State private var lines: [ChatLine] = []
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: nickname) {
            StatusText(text: error)
            ForEach(lines) { line in
                HStack {
                    if line.mine { Spacer(minLength: 40) }
                    if !line.mine { InkAvatar(url: avatarUrl.isEmpty ? nil : avatarUrl, size: 32) }
                    Text(line.text)
                        .font(InkFont.body())
                        .padding(10)
                        .background(line.mine ? palette.ink : palette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(line.mine ? palette.paper : palette.ink)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(palette.ink, lineWidth: line.mine ? 0 : 2))
                    if !line.mine { Spacer(minLength: 40) }
                    if line.mine { InkAvatar(url: session.user?.avatarUrl, size: 32) }
                }
            }
            TextField("写一句", text: $text).inkField()
            InkButton(title: "发送") { Task { await send() } }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/friends/\(studentId)/messages?limit=50"))
            let me = session.user?.studentId ?? ""
            lines = JSON.dictionaries(data["messages"]).map { row in
                ChatLine(
                    id: JSON.int(row["id"]),
                    mine: JSON.string(row["fromId"]) == me,
                    text: JSON.string(row["content"])
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func send() async {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        do {
            _ = try await session.client.post("api/friends/\(studentId)/messages", json: [
                "authToken": session.user?.token ?? "",
                "content": content,
            ])
            text = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ComposeView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "发帖") {
            TextField("写点什么", text: $text, axis: .vertical).inkField()
            StatusText(text: error)
            InkButton(title: "发布") { Task { await send() } }
        }
    }

    private func send() async {
        do {
            _ = try await session.client.post("api/posts", json: [
                "authToken": session.user?.token ?? "",
                "content": text,
            ])
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct MyContentView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @State private var posts: [PlazaPost] = []
    @State private var comments: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "我的动态") {
            StatusText(text: error)
            Text("帖子").font(InkFont.title(18))
            ForEach(posts) { post in
                Text(post.content).font(InkFont.body())
                Button("删除") { Task { await deletePost(post.id) } }
                    .font(InkFont.body(14))
                    .foregroundStyle(palette.ink)
                WavyDivider()
            }
            Text("评论").font(InkFont.title(18))
            ForEach(Array(comments.enumerated()), id: \.offset) { _, row in
                Text(row).font(InkFont.body())
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let postsData = JSON.object(try await session.client.get("api/me/posts"))
            posts = JSON.dictionaries(postsData["posts"]).compactMap { row in
                let id = JSON.int(row["id"])
                guard id > 0 else { return nil }
                return PlazaPost(
                    id: id,
                    studentId: JSON.string(row["studentId"]),
                    nickname: JSON.string(row["nickname"], fallback: "我"),
                    avatarUrl: nil,
                    content: JSON.string(row["content"]),
                    likeCount: JSON.int(row["likeCount"]),
                    commentCount: JSON.int(row["commentCount"]),
                    likedByMe: false
                )
            }
            let commentData = JSON.object(try await session.client.get("api/me/comments"))
            comments = JSON.dictionaries(commentData["comments"]).map { JSON.string($0["content"]) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func deletePost(_ id: Int) async {
        do {
            _ = try await session.client.post("api/posts/\(id)/delete", json: ["authToken": session.user?.token ?? ""])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PostDetailView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    var postId: Int
    @State private var comments: [PlazaComment] = []
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "评论") {
            StatusText(text: error)
            ForEach(comments) { item in
                Text("\(item.nickname)：\(item.content)").font(InkFont.body())
            }
            TextField("评论", text: $text).inkField()
            InkButton(title: "发送评论") { Task { await send() } }
            InkButton(title: "点赞", filled: false) { Task { await like() } }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            comments = try await PlazaAPI.comments(postId: postId, client: session.client)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func send() async {
        do {
            _ = try await session.client.post("api/posts/\(postId)/comments", json: [
                "authToken": session.user?.token ?? "",
                "content": text,
            ])
            text = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func like() async {
        do {
            _ = try await session.client.post("api/posts/\(postId)/like", json: ["authToken": session.user?.token ?? ""])
            error = "已点赞"
        } catch {
            self.error = error.localizedDescription
        }
    }
}
