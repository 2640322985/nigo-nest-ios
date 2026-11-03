import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var points = "—"
    @State private var streak = 0
    @State private var checkedIn = false
    @State private var nextAward = 0
    @State private var signing = false
    @State private var notice = ""
    @State private var friendUnread = 0
    @State private var noteUnread = 0
    @State private var features = FeatureFlags()
    @State private var titleText = ""
    @State private var shareURL: URL?


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                InkTitle(text: "在泥工，留个窝。", size: 30)
                Button { nav.open(.account) } label: {
                    HStack(spacing: 13) {
                        InkAvatar(url: session.user?.avatarUrl, size: 54)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName).font(.title3.bold())
                            Text(titleText.isEmpty ? "南京工业大学" : titleText).font(.caption).foregroundStyle(.secondary)
                            if session.isPreview { Text("演示数据").font(.caption2).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }.foregroundStyle(Palette.ink).contentShape(Rectangle())
                }.buttonStyle(.plain)
                pointsCard
                CampusGroup {
                    CampusLink(title: "我的动态", icon: "text.bubble") { nav.open(.mine) }
                    Divider()
                    CampusLink(title: "好友", icon: "person.2", badge: friendUnread) { nav.open(.friends) }
                    Divider()
                    CampusLink(title: "预约记录", icon: "calendar") { nav.open(.orders) }
                    Divider()
                    CampusLink(title: "同伴管理", icon: "person.2.wave.2") { nav.open(.buddies) }
                }
                CampusGroup {
                    DisclosureGroup {
                        InkRow(title: "课表") { nav.open(.schedule) }
                        if features.emptyClassroom { InkRow(title: "空教室") { nav.open(.classroom) } }
                        InkRow(title: "场馆预约") { nav.open(.venue) }
                        if features.courseGrab { InkRow(title: "自动抢课") { nav.open(.grab) } }
                        if showYx { InkRow(title: "迎新答题") { nav.open(.yx) } }
                        if showSafety { InkRow(title: "安全知识考试") { nav.open(.safety) } }
                        if features.chuanggaoRun { Text("创高体育 · 即将上线").font(.caption) }
                    } label: { Label("学业工具", systemImage: "book").padding(.vertical, 15) }
                    Divider()
                    CampusLink(title: "功能建议", icon: "bubble.left") { nav.open(.suggestions) }
                    Divider()
                    CampusLink(title: "账号资料", icon: "person.crop.circle") { nav.open(.account) }
                }
                HStack(spacing: 16) {
                    CampusArtwork(name: "CampusReading").frame(width: 105, height: 112)
                    Text("慢慢来，也很好。").font(.custom("MaShanZheng-Regular", size: 22, relativeTo: .body))
                }.frame(maxWidth: .infinity)
                Button("退出登录") { session.logout() }.font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.bottom, 8)
            }.padding(20)
        }
        .background(Palette.paper)
        .navigationTitle("我的小窝").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let shareURL { ShareLink(item: shareURL) { Image(systemName: "square.and.arrow.up") } }
            }
        }
        .task { await reload() }
    }

    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(points).font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("积分").font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("连续签到 \(streak) 天").font(.caption)
                    Button(checkedIn ? "已签到" : signing ? "签到中" : "签到 +\(nextAward)") { Task { await sign() } }
                        .officialAction().disabled(checkedIn || signing)
                }
                Button { nav.open(.leaderboard) } label: {
                    Image(systemName: "trophy").font(.title3).frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel("积分排行榜")
            }
            if !notice.isEmpty { Text(notice).font(.caption).foregroundStyle(.secondary) }
        }.padding(15).overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink, lineWidth: 1))
    }

    private var displayName: String {
        let name = session.user?.name ?? ""
        if !name.isEmpty { return name }
        return session.user?.nickname ?? "同学"
    }

    private var showYx: Bool {
        features.yxExam && (session.user?.studentId.hasPrefix("2026") == true)
    }

    private var showSafety: Bool {
        features.safetyExam && (session.user?.studentId.hasPrefix("2026") == true)
    }

    private func reload() async {
        async let checkin: Void = loadCheckin()
        async let badges: Void = loadBadges()
        async let flags: Void = loadFeatures()
        async let me: Void = loadMe()
        async let share: Void = loadShare()
        _ = await (checkin, badges, flags, me, share)
    }

    private func loadCheckin() async {
        guard let raw = try? await session.client.get("api/checkin") else { return }
        let data = JSON.object(raw)
        points = String(JSON.int(data["points"]))
        streak = JSON.int(data["streak"])
        checkedIn = JSON.bool(data["checkedInToday"])
        nextAward = JSON.int(data["nextAward"])
    }

    private func sign() async {
        signing = true
        defer { signing = false }
        do {
            let data = JSON.object(try await session.client.post("api/checkin", json: [:]))
            notice = JSON.bool(data["already"]) ? "今天已经签过" : "签到成功，+\(JSON.int(data["awarded"], fallback: JSON.int(data["todayAward"])))"
            await loadCheckin()
        } catch {
            notice = error.localizedDescription
        }
    }

    private func loadBadges() async {
        if let raw = try? await session.client.get("api/friends/unread-count") {
            friendUnread = JSON.int(JSON.object(raw)["unreadCount"])
        }
        if let raw = try? await session.client.get("api/notifications/unread-count") {
            noteUnread = JSON.int(JSON.object(raw)["unreadCount"])
        }
    }

    private func loadFeatures() async {
        guard let raw = try? await session.client.get("api/app/features") else { return }
        let data = JSON.object(raw)
        let src = data["features"] as? [String: Any] ?? data
        features = FeatureFlags(
            courseGrab: src["courseGrab"] == nil ? true : JSON.bool(src["courseGrab"]),
            yxExam: src["yxExam"] == nil ? true : JSON.bool(src["yxExam"]),
            safetyExam: src["safetyExam"] == nil ? true : JSON.bool(src["safetyExam"]),
            emptyClassroom: src["emptyClassroom"] == nil ? true : JSON.bool(src["emptyClassroom"]),
            chuanggaoRun: JSON.bool(src["chuanggaoRun"])
        )
    }

    private func loadMe() async {
        guard let raw = try? await session.client.get("api/user/me") else { return }
        let data = JSON.object(raw)
        let avatar = JSON.string(data["avatarUrl"])
        session.apply(
            name: JSON.string(data["name"]),
            nickname: JSON.string(data["nickname"], fallback: session.user?.nickname ?? "同学"),
            avatarUrl: avatar
        )
        let worn = data["wornTitle"] as? [String: Any]
        titleText = JSON.string(worn?["text"])
    }

    private func loadShare() async {
        guard let raw = try? await session.client.get("api/app/version?version=1.1.0") else { return }
        let data = JSON.object(raw)
        let link = JSON.string(data["apk_url"], fallback: JSON.string(data["downloadUrl"]))
        shareURL = URL(string: link)
    }
}

private struct FeatureFlags {
    var courseGrab = true
    var yxExam = true
    var safetyExam = true
    var emptyClassroom = true
    var chuanggaoRun = false
}
