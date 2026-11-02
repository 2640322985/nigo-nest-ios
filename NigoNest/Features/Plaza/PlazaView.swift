import SwiftUI

struct PlazaView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var posts: [PlazaPost] = []
    @State private var page = 1
    @State private var totalPages = 1
    @State private var loading = false
    @State private var error = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                InkTitle(text: "广场", size: 34)
                    .padding(.bottom, 8)
                HStack {
                    Button("发帖") { nav.open(.compose) }
                        .font(InkFont.body())
                        .foregroundStyle(Palette.ink)
                    Spacer()
                }
                .padding(.bottom, 12)
                if !error.isEmpty {
                    Text(error).font(InkFont.body(14))
                }
                if loading && posts.isEmpty {
                    ProgressView().tint(Palette.ink)
                }
                ForEach(posts) { post in
                    HStack(alignment: .top, spacing: 12) {
                        InkAvatar(url: post.avatarUrl, size: 44)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.nickname)
                                .font(InkFont.title(18))
                            Text(post.content)
                                .font(InkFont.body())
                                .fixedSize(horizontal: false, vertical: true)
                            Text("赞 \(post.likeCount)    评论 \(post.commentCount)")
                                .font(InkFont.body(13))
                            Button("打开") { nav.open(.post(post.id)) }
                                .font(InkFont.body(14))
                                .foregroundStyle(Palette.ink)
                        }
                    }
                    .padding(.vertical, 8)
                    WavyDivider()
                }
                HStack {
                    Button("上一页") { Task { await load(page: page - 1) } }
                        .disabled(page <= 1 || loading)
                    Spacer()
                    Text("\(page) / \(totalPages)")
                        .font(InkFont.body(14))
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
}
