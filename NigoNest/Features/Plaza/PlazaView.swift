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

                InkTitle(text: "下课，聊两句。", size: 30)
                    .padding(.bottom, 12)
                Text(session.isPreview ? "同学们的校园日常 · 演示数据" : "同学们的校园日常")
                    .font(.subheadline).foregroundStyle(.secondary).padding(.bottom, 22)
                HStack {
                    Text("最新").font(.subheadline.bold())
                        .padding(.bottom, 8).overlay(alignment: .bottom) { Capsule().frame(width: 24, height: 2) }
                    Button("我的动态") { nav.open(.mine) }.font(.subheadline).padding(.leading, 16)
                    Spacer()
                }.padding(.bottom, 14)
                Button { nav.open(.compose) } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("分享一件校园小事…")
                        Spacer()
                    }.font(.subheadline).foregroundStyle(.secondary).padding(13)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).padding(.bottom, 18)
                StatusText(text: error)
                if loading && posts.isEmpty {
                    ProgressView().tint(Palette.ink)
                }
                if posts.isEmpty && !loading && error.isEmpty {
                    ContentUnavailableView("广场还很安静", systemImage: "bubble.left", description: Text("分享一件校园小事，认识更多同学。"))
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
            .padding(20)
        }
        .background(Palette.paper)
        .navigationTitle("校园广场").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("发布动态", systemImage: "square.and.pencil") { nav.open(.compose) }
            }
        }
        .refreshable { await load(page: 1) }
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
                    Button { Task { await like(post) } } label: {
                        Label("\(post.likeCount)", systemImage: post.likedByMe ? "heart.fill" : "heart")
                    }
                    Button { Task { await toggle(post) } } label: {
                        Label("\(post.commentCount)", systemImage: "bubble.right")
                    }
                }
                .font(InkFont.body(14))
                .foregroundStyle(Palette.ink)
                if openComments == post.id {
                    commentBox(post)
                }
            }
        }
        .padding(.vertical, 10)
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
