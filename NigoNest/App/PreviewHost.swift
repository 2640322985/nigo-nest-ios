import SwiftUI

struct PreviewHost: View {
    var page: String

    var body: some View {
        switch page {
        case "plaza":
            PlazaSample()
        case "profile":
            ProfileSample()
        default:
            LoginView()
                .environmentObject(SessionStore())
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.0).font(InkFont.title(18))
                        Text(post.1).font(InkFont.body())
                        Text("赞 \(post.2)    评论 \(post.3)").font(InkFont.body(13))
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
                HStack {
                    InkTitle(text: "我的", size: 34)
                    Spacer()
                    StreetCat()
                }
                Text("薄凉")
                    .font(InkFont.body())
                    .padding(.top, 8)
                Text("202521147161")
                    .font(InkFont.body(14))
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
