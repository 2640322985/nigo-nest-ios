import SwiftUI

private struct CampusPick: Identifiable {
    var id: String
    var name: String
    var venues: [VenuePick]
}

private struct VenuePick: Identifiable {
    var id: String
    var name: String
    var sites: [SitePick]
}

private struct SitePick: Identifiable {
    var id: String
    var name: String
}

private struct SlotPick: Identifiable {
    var id: String
    var spaceId: String
    var spaceName: String
    var dataId: Int
    var timeId: String
    var label: String
    var free: Bool
}

private struct BuddyPick: Identifiable {
    var id: String
    var userId: String
    var title: String
}

struct VenueView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var campuses: [CampusPick] = []
    @State private var campusId = ""
    @State private var venueId = ""
    @State private var siteId = ""
    @State private var dates: [String] = []
    @State private var date = ""
    @State private var slots: [SlotPick] = []
    @State private var buddies: [BuddyPick] = []
    @State private var chosen: Set<String> = []
    @State private var notice = ""
    @State private var error = ""
    @State private var needPhone = false
    @State private var phone = ""
    @State private var buddyMin = 0

    var body: some View {
        PageScaffold(title: "场馆预约") {
            HStack {
                Button("预约记录") { nav.open(.orders) }
                Spacer()
                Button("同伴管理") { nav.open(.buddies) }
            }
            .font(InkFont.body())
            .foregroundStyle(palette.ink)
            StatusText(text: error)
            if !notice.isEmpty { Text(notice).font(InkFont.body(14)) }
            Text("校区").font(InkFont.body(13))
            chipRow(campuses.map { ($0.id, $0.name) }, selected: campusId) { id in
                campusId = id
                venueId = venues.first?.id ?? ""
                siteId = venues.first?.sites.first?.id ?? ""
                Task { await loadSlots() }
            }
            Text("场馆").font(InkFont.body(13))
            chipRow(venues.map { ($0.id, $0.name) }, selected: venueId) { id in
                venueId = id
                siteId = venues.first { $0.id == id }?.sites.first?.id ?? ""
                Task { await loadSlots() }
            }
            Text("场地").font(InkFont.body(13))
            chipRow(sites.map { ($0.id, $0.name) }, selected: siteId) { id in
                siteId = id
                Task { await loadSlots() }
            }
            Text("日期").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(dates, id: \.self) { day in
                        InkChoice(title: day, selected: date == day) {
                            date = day
                            Task { await loadSlots() }
                        }
                    }
                }
            }
            if needPhone {
                TextField("联系电话", text: $phone).inkField()
            }
            if !buddies.isEmpty {
                Text(buddyMin > 0 ? "同伴，至少 \(buddyMin) 人" : "同伴").font(InkFont.body(13))
                ForEach(buddies) { buddy in
                    InkChoice(title: buddy.title, selected: chosen.contains(buddy.userId)) {
                        if chosen.contains(buddy.userId) { chosen.remove(buddy.userId) } else { chosen.insert(buddy.userId) }
                    }
                }
            }
            ForEach(slots) { slot in
                Button(slot.label) { Task { await book(slot) } }
                    .font(InkFont.body())
                    .foregroundStyle(palette.ink)
                    .disabled(!slot.free)
                    .padding(.vertical, 6)
                WavyDivider()
            }
        }
        .task { await catalog() }
    }

    private var venues: [VenuePick] {
        campuses.first { $0.id == campusId }?.venues ?? []
    }

    private var sites: [SitePick] {
        venues.first { $0.id == venueId }?.sites ?? []
    }

    private func chipRow(_ items: [(String, String)], selected: String, choose: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    InkChoice(title: item.1, selected: selected == item.0) { choose(item.0) }
                }
            }
        }
    }

    private func catalog() async {
        do {
            let data = JSON.object(try await session.client.get("api/venue/catalog"))
            needPhone = JSON.bool(data["needPhone"])
            let days = max(JSON.int(data["advanceDays"], fallback: 1), 1)
            dates = (0..<days).map { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                return Self.dayText(day)
            }
            date = dates.first ?? Self.dayText(Date())
            campuses = JSON.dictionaries(data["campuses"]).map { campus in
                CampusPick(
                    id: JSON.string(campus["id"]),
                    name: JSON.string(campus["name"]),
                    venues: JSON.dictionaries(campus["venues"]).map { venue in
                        VenuePick(
                            id: JSON.string(venue["id"]),
                            name: JSON.string(venue["name"]),
                            sites: JSON.dictionaries(venue["sites"]).map { site in
                                SitePick(id: JSON.string(site["id"]), name: JSON.string(site["name"]))
                            }
                        )
                    }
                )
            }
            campusId = campuses.first?.id ?? ""
            venueId = venues.first?.id ?? ""
            siteId = sites.first?.id ?? ""
            let buddyData = JSON.object(try await session.client.get("api/venue/buddies"))
            buddies = JSON.dictionaries(buddyData["buddies"]).map { row in
                BuddyPick(
                    id: JSON.string(row["id"], fallback: JSON.string(row["userId"])),
                    userId: JSON.string(row["userId"], fallback: JSON.string(row["id"])),
                    title: "\(JSON.string(row["name"])) \(JSON.string(row["userUid"]))"
                )
            }
            await loadSlots()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadSlots() async {
        guard !siteId.isEmpty, !date.isEmpty else { return }
        do {
            let data = JSON.object(try await session.client.get("api/venue/slots?venueSiteId=\(siteId)&date=\(date)"))
            notice = JSON.string(data["notice"])
            buddyMin = JSON.int(data["buddyMin"])
            var next: [SlotPick] = []
            for space in JSON.dictionaries(data["spaces"]) {
                let spaceName = JSON.string(space["name"])
                let spaceId = JSON.string(space["id"])
                let dataId = JSON.int(space["dataId"])
                for slot in JSON.dictionaries(space["slots"]) {
                    let free = JSON.bool(slot["free"])
                    let timeId = JSON.string(slot["timeId"])
                    let price = JSON.double(slot["price"])
                    let priceText = price == nil ? "" : "  ¥\(price!)"
                    next.append(SlotPick(
                        id: "\(spaceId)-\(timeId)",
                        spaceId: spaceId,
                        spaceName: spaceName,
                        dataId: dataId,
                        timeId: timeId,
                        label: "\(spaceName) \(JSON.string(slot["begin"]))-\(JSON.string(slot["end"])) \(JSON.string(slot["statusText"]))\(priceText)",
                        free: free
                    ))
                }
            }
            slots = next
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func book(_ slot: SlotPick) async {
        guard slot.free else { return }
        if buddyMin > 0 && chosen.count < buddyMin {
            error = "这个场地至少需要 \(buddyMin) 位同伴"
            return
        }
        var json: [String: Any] = [
            "authToken": session.user?.token ?? "",
            "venueSiteId": siteId,
            "date": date,
            "spaceId": slot.spaceId,
            "timeId": slot.timeId,
            "dataId": slot.dataId,
            "buddyIds": Array(chosen),
        ]
        if !phone.isEmpty { json["phone"] = phone }
        do {
            let data = JSON.object(try await session.client.post("api/venue/book", json: json))
            error = JSON.string(data["message"], fallback: "已提交")
            if JSON.bool(data["needPay"]) { nav.open(.orders) }
            await loadSlots()
        } catch {
            self.error = error.localizedDescription
        }
    }

    static func dayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

struct VenueOrdersView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @State private var rows: [(title: String, trade: String, canPay: Bool)] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "预约记录") {
            StatusText(text: error)
            InkButton(title: "刷新", filled: false) { Task { await load() } }
            ForEach(rows, id: \.trade) { row in
                Text(row.title).font(InkFont.body())
                if row.canPay {
                    InkButton(title: "去支付") { Task { await pay(row.trade) } }
                }
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/venue/orders"))
            rows = JSON.dictionaries(data["orders"]).map { row in
                (
                    "\(JSON.string(row["venue"]))\n\(JSON.string(row["when"]))\n\(JSON.string(row["orderStatusText"]))  \(JSON.string(row["payStatusText"]))",
                    JSON.string(row["tradeNo"]),
                    JSON.bool(row["canPay"])
                )
            }
            error = rows.isEmpty ? "还没有预约" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func pay(_ trade: String) async {
        do {
            let data = JSON.object(try await session.client.post("api/venue/pay", json: [
                "authToken": session.user?.token ?? "",
                "tradeNo": trade,
            ]))
            let link = JSON.string(data["openUrl"])
            let target = link.isEmpty ? "https://ggtypt.njtech.edu.cn/venue/pay-order?tradeNo=\(trade)" : link
            if let url = URL(string: target) {
                await UIApplication.shared.open(url)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct BuddiesView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @State private var rows: [(id: String, title: String)] = []
    @State private var uid = ""
    @State private var name = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "同伴") {
            TextField("学工号或手机号", text: $uid).inkField()
            TextField("姓名，学校要求时再填", text: $name).inkField()
            InkButton(title: "添加同伴") { Task { await add() } }
            StatusText(text: error)
            ForEach(rows, id: \.id) { row in
                HStack {
                    Text(row.title).font(InkFont.body())
                    Spacer()
                    Button("删除") { Task { await remove(row.id) } }
                        .foregroundStyle(palette.ink)
                }
                WavyDivider()
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/venue/buddies"))
            rows = JSON.dictionaries(data["buddies"]).map { row in
                (JSON.string(row["id"], fallback: JSON.string(row["userId"])), "\(JSON.string(row["name"])) \(JSON.string(row["userUid"]))")
            }
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func add() async {
        var json: [String: Any] = ["authToken": session.user?.token ?? "", "userUid": uid]
        if !name.isEmpty { json["checkName"] = name }
        do {
            _ = try await session.client.post("api/venue/buddies", json: json)
            uid = ""
            name = ""
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func remove(_ id: String) async {
        do {
            _ = try await session.client.post("api/venue/buddies/remove", json: [
                "authToken": session.user?.token ?? "",
                "id": id,
            ])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
