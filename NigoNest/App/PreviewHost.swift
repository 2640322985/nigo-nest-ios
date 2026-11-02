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
                        Text("2026-2027 第一学期").font(InkFont.body(14))
                        Text("周一").font(InkFont.title(20))
                        HStack(alignment: .top, spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Palette.course[0])
                                .frame(width: 4, height: 52)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("高等数学").font(InkFont.title(18))
                                Text("1-2 节  博学楼 A203").font(InkFont.body(14))
                                Text("带计算器").font(InkFont.body(14))
                            }
                        }
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
                HStack {
                    InkTitle(text: "广场", size: 34)
                    Spacer()
                    Text("发帖").font(InkFont.body())
                }
                .padding(.bottom, 12)
                ForEach(Array(posts.enumerated()), id: \.offset) { _, post in
                    HStack(alignment: .top, spacing: 12) {
                        InkAvatar(size: 44)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.0).font(InkFont.title(18))
                            Text(post.1).font(InkFont.body())
                            HStack(spacing: 16) {
                                Text("赞 \(post.2)")
                                Text("评论 \(post.3)")
                            }
                            .font(InkFont.body(14))
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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    InkTitle(text: "我的", size: 34)
                    Spacer()
                    Text("分享").font(InkFont.body())
                }
                HStack(alignment: .center, spacing: 14) {
                    InkAvatar(size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("薄凉").font(InkFont.title(20))
                        Text("同学").font(InkFont.body(14))
                        Text("账号资料").font(InkFont.body(13))
                    }
                }
                .padding(.top, 16)
                WavyDivider()
                Text("每日签到").font(InkFont.body(13)).padding(.top, 8)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的积分").font(InkFont.body(13))
                        Text("128").font(InkFont.title(36))
                        Text("今日签到 +6").font(InkFont.body(13))
                        Text("连续 3 天").font(InkFont.body(13))
                    }
                    Spacer()
                    Button("签到") {}
                        .officialAction()
                }
                .padding(.vertical, 8)
                InkRow(title: "积分排行榜") {}
                WavyDivider()
                Text("教务").font(InkFont.body(13))
                InkRow(title: "课表") {}
                InkRow(title: "空教室") {}
                InkRow(title: "场馆预约") {}
                WavyDivider()
                Text("广场").font(InkFont.body(13))
                InkRow(title: "好友", badge: 2) {}
                InkRow(title: "消息通知", badge: 5) {}
                InkRow(title: "我的动态") {}
            }
            .padding(24)
            .foregroundStyle(Palette.ink)
        }
        .background(Palette.paper)
    }
}
