import SwiftUI

struct PlazaView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var posts: [PlazaPost] = []
    @State private var page = 1
    @State private var totalPages = 1
    @State private var loading = false
    @State private var error = ""
    @State private var openComments: Int?
    @State private var comments: [Int: [PlazaComment]] = [:]
    @State private var draft = ""
    @State private var replyId: Int?
    @State private var replyName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    InkTitle(text: "广场", size: 34)
                    Spacer()
                    Button("发帖") { nav.open(.compose) }
                        .font(InkFont.body())
                        .foregroundStyle(Palette.ink)
                }
                .padding(.bottom, 12)
                StatusText(text: error)
                if loading && posts.isEmpty {
                    ProgressView().tint(Palette.ink)
                }
                ForEach(posts) { post in
                    postCard(post)
                    WavyDivider()
                }
                HStack {
                    Button("上一页") { Task { await load(page: page - 1) } }
                        .disabled(page <= 1 || loading)
                    Spacer()
                    Text("\(page) / \(totalPages)").font(InkFont.body(14))
                    Spacer()
                    Button("下一页") { Task { await load(page: page + 1) } }
                        .disabled(page >= totalPages || loading)
                }
                .font(InkFont.body())
                .foregroundStyle(Palette.ink)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Palette.paper)
        .task { await load(page: 1) }
    }

    private func postCard(_ post: PlazaPost) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { nav.open(.user(post.studentId)) } label: {
                InkAvatar(url: post.avatarUrl, size: 44)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 8) {
                Button(post.nickname) { nav.open(.user(post.studentId)) }
                    .font(InkFont.title(18))
                    .foregroundStyle(Palette.ink)
                Text(post.content)
                    .font(InkFont.body())
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Button(post.likedByMe ? "已赞 \(post.likeCount)" : "赞 \(post.likeCount)") {
                        Task { await like(post) }
                    }
                    Button("评论 \(post.commentCount)") { Task { await toggle(post) } }
                }
                .font(InkFont.body(14))
                .foregroundStyle(Palette.ink)
                if openComments == post.id {
                    commentBox(post)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func commentBox(_ post: PlazaPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(comments[post.id] ?? []) { item in
                HStack(alignment: .top, spacing: 8) {
                    InkAvatar(url: item.avatarUrl, size: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.nickname).font(InkFont.body(13))
                        if !item.replyName.isEmpty {
                            Text("回复 \(item.replyName)").font(InkFont.body(12))
                        }
                        Text(item.content).font(InkFont.body(14))
                    }
                }
                .onTapGesture {
                    replyId = item.id
                    replyName = item.nickname
                }
            }
            if !replyName.isEmpty {
                Text("回复 \(replyName)").font(InkFont.body(12))
            }
            TextField("写评论", text: $draft).inkField()
            Button("发送") { Task { await send(post) } }
                .font(InkFont.body())
                .foregroundStyle(Palette.ink)
        }
    }

    private func load(page next: Int) async {
        guard next >= 1 else { return }
        loading = true
        defer { loading = false }
        do {
            let result = try await PlazaAPI.load(page: next, client: session.client)
            posts = result.posts
            page = next
            totalPages = result.totalPages
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func like(_ post: PlazaPost) async {
        do {
            let data = JSON.object(try await session.client.post("api/posts/\(post.id)/like", json: [
                "authToken": session.user?.token ?? "",
            ]))
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].likedByMe = JSON.bool(data["liked"])
                posts[index].likeCount = JSON.int(data["likeCount"], fallback: posts[index].likeCount)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func toggle(_ post: PlazaPost) async {
        if openComments == post.id {
            openComments = nil
            return
        }
        openComments = post.id
        replyId = nil
        replyName = ""
        do {
            comments[post.id] = try await PlazaAPI.comments(postId: post.id, client: session.client)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func send(_ post: PlazaPost) async {
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        var json: [String: Any] = ["authToken": session.user?.token ?? "", "content": content]
        if let replyId { json["replyToId"] = replyId }
        do {
            _ = try await session.client.post("api/posts/\(post.id)/comments", json: json)
            draft = ""
            replyId = nil
            replyName = ""
            comments[post.id] = try await PlazaAPI.comments(postId: post.id, client: session.client)
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index].commentCount += 1
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
