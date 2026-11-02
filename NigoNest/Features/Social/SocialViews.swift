import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var friends: [(id: String, name: String)] = []
    @State private var incoming: [(id: String, name: String)] = []
    @State private var target = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "好友") {
            TextField("对方学号", text: $target).inkField()
            InkButton(title: "加好友") { Task { await requestFriend() } }
            StatusText(text: error)
            Text("收到的申请").font(InkFont.title(18))
            ForEach(incoming, id: \.id) { item in
                HStack(spacing: 12) {
                    InkAvatar(size: 40)
                    Text(item.name).font(InkFont.body())
                    Spacer()
                    Button("同意") { Task { await accept(item.id) } }
                    Button("拒绝") { Task { await reject(item.id) } }
                }
                .foregroundStyle(Palette.ink)
            }
            WavyDivider()
            ForEach(friends, id: \.id) { item in
                HStack(spacing: 12) {
                    InkAvatar(size: 40)
                    InkRow(title: item.name) { nav.open(.chat(item.id, item.name)) }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/friends"))
            friends = JSON.dictionaries(data["friends"]).map { (JSON.string($0["studentId"]), JSON.string($0["nickname"])) }
            incoming = JSON.dictionaries(data["incoming"]).map { (JSON.string($0["studentId"]), JSON.string($0["nickname"])) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func requestFriend() async {
        do {
            _ = try await session.client.post("api/friends/request", json: [
                "authToken": session.user?.token ?? "",
                "targetStudentId": target,
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

struct ChatView: View {
    @EnvironmentObject private var session: SessionStore
    var studentId: String
    var nickname: String
    @State private var lines: [String] = []
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: nickname) {
            StatusText(text: error)
            ForEach(lines, id: \.self) { line in
                Text(line).font(InkFont.body()).frame(maxWidth: .infinity, alignment: .leading)
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
                let who = JSON.string(row["fromId"]) == me ? "我" : nickname
                return "\(who)：\(JSON.string(row["content"]))"
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
    @EnvironmentObject private var session: SessionStore
    @State private var rows: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "我的动态") {
            StatusText(text: error)
            ForEach(rows, id: \.self) { row in
                Text(row).font(InkFont.body())
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let posts = JSON.object(try await session.client.get("api/me/posts"))
            let comments = JSON.object(try await session.client.get("api/me/comments"))
            rows = JSON.dictionaries(posts["posts"]).map { "帖子  \(JSON.string($0["content"]))" }
                + JSON.dictionaries(comments["comments"]).map { "评论  \(JSON.string($0["content"]))" }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct PostDetailView: View {
    @EnvironmentObject private var session: SessionStore
    var postId: Int
    @State private var comments: [String] = []
    @State private var text = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "评论") {
            StatusText(text: error)
            ForEach(comments, id: \.self) { item in
                Text(item).font(InkFont.body())
            }
            TextField("评论", text: $text).inkField()
            InkButton(title: "发送评论") { Task { await send() } }
            InkButton(title: "点赞", filled: false) { Task { await like() } }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/posts/\(postId)/comments"))
            comments = JSON.dictionaries(data["comments"]).map { "\(JSON.string($0["nickname"]))：\(JSON.string($0["content"]))" }
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
        } catch {
            self.error = error.localizedDescription
        }
    }
}
