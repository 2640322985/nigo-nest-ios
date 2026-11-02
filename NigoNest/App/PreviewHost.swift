import SwiftUI

struct PreviewHost: View {
    var page: String

    var body: some View {
        switch page {
        case "plaza":
            PreviewTabs(selection: 0)
        case "profile":
            PreviewTabs(selection: 1)
        case "back":
            BackSample()
        default:
            LoginView()
                .environmentObject(SessionStore())
        }
    }
}

private struct PreviewTabs: View {
    var selection: Int

    var body: some View {
        TabView(selection: .constant(selection)) {
            Tab("广场", systemImage: "bubble.left.and.bubble.right", value: 0) {
                PlazaSample()
            }
            Tab("我的", systemImage: "person", value: 1) {
                ProfileSample()
            }
        }
    }
}

private struct BackSample: View {
    @State private var path = [0]

    var body: some View {
        NavigationStack(path: $path) {
            PlazaSample()
                .navigationTitle("广场")
                .navigationDestination(for: Int.self) { _ in
                    PageScaffold(title: "课表") {
                        Text("下一节课的备注写在这里")
                            .font(InkFont.body())
                    }
                }
        }
    }
}

private struct PlazaSample: View {
    private let posts: [(String, String, Int, Int)] = [
        ("薄凉", "今天下午机房空着，需要自习的同学可以去。", 1, 0),
        ("王瑞严父", "课表备注很好用。", 0, 0)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                InkTitle(text: "广场", size: 34)
                    .padding(.bottom, 8)
                Text("泥工小窝 · 校园动态")
                    .font(InkFont.body(14))
                    .padding(.bottom, 20)
                ForEach(Array(posts.enumerated()), id: \.offset) { _, post in
                    HStack(alignment: .top, spacing: 12) {
                        InkAvatar(size: 44)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.0).font(InkFont.title(18))
                            Text(post.1).font(InkFont.body())
                            Text("赞 \(post.2)    评论 \(post.3)").font(InkFont.body(13))
                        }
                    }
                    .padding(.vertical, 8)
                    WavyDivider()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.paper)
    }
}

private struct ProfileSample: View {
    private let rows = ["课表", "空教室", "场馆预约", "签到", "功能建议"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                InkTitle(text: "我的", size: 34)
                HStack(alignment: .center, spacing: 14) {
                    InkAvatar(size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("薄凉")
                            .font(InkFont.title(20))
                        Text("202521147161")
                            .font(InkFont.body(14))
                    }
                }
                .padding(.top, 16)
                WavyDivider()
                ForEach(rows, id: \.self) { name in
                    InkRow(title: name) {}
                    WavyDivider()
                }
            }
            .padding(24)
        }
        .background(Palette.paper)
    }
}
