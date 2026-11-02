import SwiftUI

struct VenueView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @State private var sites: [(id: String, name: String)] = []
    @State private var siteId = ""
    @State private var date = ""
    @State private var spaceId = ""
    @State private var timeId = ""
    @State private var dataId = ""
    @State private var slots: [String] = []
    @State private var error = ""
    @State private var buddyIds = ""

    var body: some View {
        PageScaffold(title: "场馆预约") {
            HStack {
                InkButton(title: "记录", filled: false) { nav.open(.orders) }
                InkButton(title: "同伴", filled: false) { nav.open(.buddies) }
            }
            StatusText(text: error)
            ForEach(sites, id: \.id) { site in
                InkRow(title: site.name) {
                    siteId = site.id
                    Task { await loadSlots() }
                }
            }
            TextField("日期 2026-11-02", text: $date).inkField()
            TextField("场地编号", text: $spaceId).inkField()
            TextField("时段编号", text: $timeId).inkField()
            TextField("dataId", text: $dataId).inkField()
            TextField("同伴编号，逗号分隔", text: $buddyIds).inkField()
            InkButton(title: "提交预约") { Task { await book() } }
            ForEach(slots, id: \.self) { line in
                Text(line).font(InkFont.body(14))
            }
        }
        .task { await catalog() }
    }

    private func catalog() async {
        do {
            let data = JSON.object(try await session.client.get("api/venue/catalog"))
            var next: [(id: String, name: String)] = []
            for campus in JSON.dictionaries(data["campuses"]) {
                for venue in JSON.dictionaries(campus["venues"]) {
                    for site in JSON.dictionaries(venue["sites"]) {
                        next.append((JSON.string(site["id"]), JSON.string(site["name"])))
                    }
                }
            }
            sites = next
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadSlots() async {
        let day = date.isEmpty ? Self.today() : date
        date = day
        do {
            let data = JSON.object(try await session.client.get("api/venue/slots?venueSiteId=\(siteId)&date=\(day)"))
            var lines: [String] = []
            for space in JSON.dictionaries(data["spaces"]) {
                let spaceName = JSON.string(space["name"])
                let spaceId = JSON.string(space["id"])
                let dataId = JSON.int(space["dataId"])
                for slot in JSON.dictionaries(space["slots"]) {
                    let free = JSON.bool(slot["free"])
                    let timeId = JSON.string(slot["timeId"])
                    let label = "\(spaceName) \(JSON.string(slot["begin"]))-\(JSON.string(slot["end"])) \(JSON.string(slot["statusText"]))"
                    lines.append(free ? label + "  可约 \(spaceId) \(timeId) \(dataId)" : label)
                }
            }
            slots = lines
            error = JSON.string(data["notice"])
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func book() async {
        let ids = buddyIds.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        do {
            let data = JSON.object(try await session.client.post("api/venue/book", json: [
                "authToken": session.user?.token ?? "",
                "venueSiteId": siteId,
                "date": date,
                "spaceId": spaceId,
                "timeId": timeId,
                "dataId": Int(dataId) ?? 0,
                "buddyIds": ids,
            ]))
            error = JSON.string(data["message"], fallback: "已提交")
            if JSON.bool(data["needPay"]) {
                nav.open(.orders)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    static func today() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
}

struct VenueOrdersView: View {
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
                    "\(JSON.string(row["venue"])) \(JSON.string(row["when"])) \(JSON.string(row["payStatusText"]))",
                    JSON.string(row["tradeNo"]),
                    JSON.bool(row["canPay"])
                )
            }
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
                        .foregroundStyle(Palette.ink)
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
                (JSON.string(row["id"]), "\(JSON.string(row["name"])) \(JSON.string(row["userUid"]))")
            }
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
