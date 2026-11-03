import SwiftUI

struct PageScaffold<Content: View>: View {
    @ThemePalette private var palette
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InkTitle(text: title, size: 32)
                content()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ThemePaper())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

struct StatusText: View {
    @ThemePalette private var palette
    var text: String
    var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            Text(text).font(InkFont.body(14)).foregroundStyle(palette.ink)
        }
    }
}

struct CheckinView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var points = "—"
    @State private var hint = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "签到") {
            Text(points).font(InkFont.title(42))
            Text(hint).font(InkFont.body(14))
            StatusText(text: error)
            InkButton(title: "签到") { Task { await sign() } }
            InkButton(title: "积分排行榜", filled: false) { nav.open(.leaderboard) }
        }
        .task { await reload() }
    }

    private func reload() async {
        do {
            let data = JSON.object(try await session.client.get("api/checkin"))
            points = String(JSON.int(data["points"]))
            let streak = JSON.int(data["streak"])
            let today = JSON.bool(data["checkedInToday"])
            hint = today ? "已签到，连续 \(streak) 天" : "今日可领 \(JSON.int(data["nextAward"])) 积分"
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func sign() async {
        do {
            _ = try await session.client.post("api/checkin", json: [:])
            await reload()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct LeaderboardView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @State private var rows: [(rank: Int, name: String, points: Int, mine: Bool)] = []
    @State private var me = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "排行榜") {
            StatusText(text: error)
            if !me.isEmpty { Text(me).font(InkFont.body()) }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text("\(row.rank)")
                        .font(InkFont.title(18))
                        .frame(width: 36, alignment: .leading)
                    Text(row.name).font(row.mine ? InkFont.title(16) : InkFont.body())
                    Spacer()
                    Text("\(row.points)").font(InkFont.body())
                }
                .foregroundStyle(palette.ink)
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/checkin/leaderboard"))
            rows = JSON.dictionaries(data["items"]).map { row in
                (JSON.int(row["rank"]), JSON.string(row["name"]), JSON.int(row["points"]), JSON.bool(row["isMe"]))
            }
            let mine = data["me"] as? [String: Any] ?? [:]
            let rank = JSON.int(mine["rank"])
            me = rank > 0 ? "我的名次 \(rank)  ·  \(JSON.int(mine["points"])) 分" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SuggestionsView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @State private var text = ""
    @State private var rows: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "功能建议") {
            TextField("想加什么功能", text: $text, axis: .vertical)
                .font(InkFont.body())
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.ink, lineWidth: 3))
            InkButton(title: "提交建议") { Task { await send() } }
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
            let data = JSON.object(try await session.client.get("api/suggestions"))
            rows = JSON.dictionaries(data["suggestions"]).map { row in
                let status = JSON.string(row["status"])
                let label = status == "accepted" ? "已采纳" : status == "rejected" ? "未采纳" : "待处理"
                let reply = JSON.string(row["reply"])
                return "\(label)  \(JSON.string(row["content"]))" + (reply.isEmpty ? "" : "\n回复：\(reply)")
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func send() async {
        do {
            _ = try await session.client.post("api/suggestions", json: ["content": text])
            text = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct NoteItem: Identifiable {
    var id: Int
    var title: String
    var body: String
    var read: Bool
    var type: String
    var refId: Int
}

struct NotificationsView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var rows: [NoteItem] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "消息") {
            StatusText(text: error)
            InkButton(title: "全部已读", filled: false) { Task { await readAll() } }
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title).font(row.read ? InkFont.body() : InkFont.title(16))
                    Text(row.body).font(InkFont.body(14))
                }
                .onTapGesture { Task { await open(row) } }
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/notifications?page=1&pageSize=30"))
            rows = JSON.dictionaries(data["notifications"]).map { row in
                NoteItem(
                    id: JSON.int(row["id"]),
                    title: JSON.string(row["title"]),
                    body: JSON.string(row["body"]),
                    read: !JSON.string(row["readAt"]).isEmpty,
                    type: JSON.string(row["type"]),
                    refId: JSON.int(row["refId"])
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func open(_ row: NoteItem) async {
        _ = try? await session.client.post("api/notifications/\(row.id)/read", json: [:])
        switch row.type {
        case "friend_request", "friend_accepted":
            nav.open(.friends)
        case "post_like", "post_comment":
            if row.refId > 0 { nav.open(.post(row.refId)) }
        case "course_grab":
            nav.open(.grab)
        case "yx_exam":
            nav.open(.yx)
        case "bwcks_exam":
            nav.open(.safety)
        case "suggestion":
            nav.open(.suggestions)
        default:
            break
        }
        await load()
    }

    private func readAll() async {
        do {
            _ = try await session.client.post("api/notifications/read-all", json: [:])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
