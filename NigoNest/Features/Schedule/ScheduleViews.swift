import SwiftUI

private struct CourseItem: Identifiable {
    var id: String
    var name: String
    var weekday: Int
    var start: Int
    var end: Int
    var place: String
    var teacher: String
    var noteKey: String
    var note: String
}

struct ScheduleView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var courses: [CourseItem] = []
    @State private var term = ""
    @State private var xnm = ""
    @State private var xqm = ""
    @State private var error = ""
    @State private var selected: String?
    @State private var note = ""
    @State private var busy = false

    private let days = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        PageScaffold(title: "课表") {
            Text(term.isEmpty ? "还没有课表" : term).font(InkFont.body(14))
            StatusText(text: error)
            InkButton(title: busy ? "导入中" : "从教务导入") { Task { await importSchedule() } }
                .disabled(busy)
            ForEach(1...7, id: \.self) { day in
                let rows = courses.filter { $0.weekday == day }
                if !rows.isEmpty {
                    Text("周\(days[day - 1])").font(InkFont.title(20)).padding(.top, 8)
                    ForEach(rows) { course in
                        HStack(alignment: .top, spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Palette.course[(course.start - 1) % Palette.course.count])
                                .frame(width: 4)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.name).font(InkFont.title(18))
                                Text("\(course.start)-\(course.end) 节  \(course.place)").font(InkFont.body(14))
                                if !course.teacher.isEmpty {
                                    Text(course.teacher).font(InkFont.body(13))
                                }
                                if !course.note.isEmpty {
                                    Text(course.note).font(InkFont.body(14))
                                }
                            }
                        }
                        .onTapGesture {
                            selected = course.noteKey
                            note = course.note
                        }
                    }
                }
            }
            if let selected {
                WavyDivider()
                Text("备注").font(InkFont.title(18))
                Text(selected).font(InkFont.body(12))
                TextField("这节课要做的事", text: $note, axis: .vertical).inkField()
                InkButton(title: "保存备注") { Task { await saveNote() } }
                InkButton(title: "清除", filled: false) {
                    note = ""
                    Task { await saveNote() }
                }
            }
        }
    }

    private func importSchedule() async {
        busy = true
        defer { busy = false }
        do {
            let data = JSON.object(try await session.client.post("api/schedule/import", json: [
                "authToken": session.user?.token ?? "",
            ]))
            let schedule = data["schedule"] as? [String: Any] ?? [:]
            xnm = JSON.string(schedule["xnm"])
            xqm = JSON.string(schedule["xqm"])
            term = JSON.string(schedule["termLabel"])
            var notes: [String: String] = [:]
            if !xnm.isEmpty {
                let noteData = JSON.object(try await session.client.get("api/schedule/notes?xnm=\(xnm)&xqm=\(xqm)"))
                for row in JSON.dictionaries(noteData["notes"]) {
                    notes[JSON.string(row["courseKey"])] = JSON.string(row["text"])
                }
            }
            courses = JSON.dictionaries(schedule["courses"]).enumerated().map { index, row in
                let name = JSON.string(row["name"])
                let weekday = JSON.int(row["weekday"], fallback: 1)
                let sections = JSON.dictionaries(row["sections"])
                let start = JSON.int(sections.first?["start"], fallback: 1)
                let end = JSON.int(sections.first?["end"], fallback: start)
                let identity = JSON.string(row["id"]).split(separator: "|").first.map(String.init) ?? name
                let key = "\(identity)|\(weekday)|\(start)-\(end)"
                return CourseItem(
                    id: "\(key)-\(index)",
                    name: name,
                    weekday: min(max(weekday, 1), 7),
                    start: start,
                    end: end,
                    place: JSON.string(row["location"]),
                    teacher: JSON.string(row["teacher"], fallback: JSON.string(row["teacherName"])),
                    noteKey: key,
                    note: notes[key] ?? ""
                )
            }
            publishWidget()
            error = courses.isEmpty ? "这个学期没有课程" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveNote() async {
        guard let selected else { return }
        do {
            _ = try await session.client.post("api/schedule/notes", json: [
                "authToken": session.user?.token ?? "",
                "xnm": xnm,
                "xqm": xqm,
                "courseKey": selected,
                "text": note,
            ])
            if let index = courses.firstIndex(where: { $0.noteKey == selected }) {
                courses[index].note = note
            }
            publishWidget()
            error = note.isEmpty ? "已清除" : "备注已保存"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func publishWidget() {
        let today = Calendar.current.component(.weekday, from: Date())
        let mapped = today == 1 ? 7 : today - 1
        let next = courses.first { $0.weekday == mapped } ?? courses.first
        let defaults = UserDefaults(suiteName: "group.com.nigo.nest")
        defaults?.set(next?.name ?? "打开泥工小窝同步课表", forKey: "widget.course")
        if let next {
            defaults?.set("周\(days[next.weekday - 1]) \(next.start)-\(next.end) 节 \(next.place)", forKey: "widget.time")
            defaults?.set(next.note, forKey: "widget.note")
        }
    }
}

private struct Choice: Identifiable, Hashable {
    var id: String
    var name: String
}

struct ClassroomView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var campuses: [Choice] = []
    @State private var buildings: [Choice] = []
    @State private var campusId = ""
    @State private var building = ""
    @State private var week = 1
    @State private var weekday = 1
    @State private var periods: Set<Int> = []
    @State private var rooms: [String] = []
    @State private var error = ""
    @State private var busy = false

    var body: some View {
        PageScaffold(title: "空教室") {
            Text("校区").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(campuses) { item in
                        InkChoice(title: item.name, selected: campusId == item.id) {
                            campusId = item.id
                            Task { await loadMeta() }
                        }
                    }
                }
            }
            Text("楼栋").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    InkChoice(title: "全部", selected: building.isEmpty) { building = "" }
                    ForEach(buildings) { item in
                        InkChoice(title: item.name, selected: building == item.name) { building = item.name }
                    }
                }
            }
            Text("周次").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(1...20, id: \.self) { value in
                        InkChoice(title: "\(value)", selected: week == value) { week = value }
                    }
                }
            }
            Text("星期").font(InkFont.body(13))
            HStack {
                ForEach(1...7, id: \.self) { value in
                    InkChoice(title: ["一", "二", "三", "四", "五", "六", "日"][value - 1], selected: weekday == value) {
                        weekday = value
                    }
                }
            }
            Text("节次").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(1...12, id: \.self) { value in
                        InkChoice(title: "\(value)", selected: periods.contains(value)) {
                            if periods.contains(value) { periods.remove(value) } else { periods.insert(value) }
                        }
                    }
                }
            }
            InkButton(title: busy ? "查询中" : "查询") { Task { await query() } }
                .disabled(busy)
            StatusText(text: error)
            ForEach(rooms, id: \.self) { room in
                Text(room).font(InkFont.body())
                WavyDivider()
            }
        }
        .task { await loadMeta() }
    }

    private func loadMeta() async {
        var path = "api/classroom/meta"
        if !campusId.isEmpty {
            path += "?campusId=\(campusId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? campusId)"
        }
        do {
            let data = JSON.object(try await session.client.get(path))
            campuses = JSON.dictionaries(data["campuses"]).map {
                Choice(id: JSON.string($0["id"], fallback: JSON.string($0["name"])), name: JSON.string($0["name"]))
            }
            buildings = JSON.dictionaries(data["buildings"]).map {
                Choice(id: JSON.string($0["id"], fallback: JSON.string($0["name"])), name: JSON.string($0["name"]))
            }
            if campusId.isEmpty { campusId = campuses.first?.id ?? "" }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func query() async {
        busy = true
        defer { busy = false }
        var json: [String: Any] = [
            "authToken": session.user?.token ?? "",
            "week": week,
            "weekday": weekday,
        ]
        if !campusId.isEmpty { json["campusId"] = campusId }
        if !building.isEmpty { json["building"] = building }
        if !periods.isEmpty { json["periods"] = periods.sorted() }
        do {
            let data = JSON.object(try await session.client.post("api/classroom/empty", json: json))
            rooms = JSON.dictionaries(data["rooms"]).map { row in
                let seats = JSON.int(row["seats"])
                let seatText = seats > 0 ? "  \(seats)座" : ""
                return "\(JSON.string(row["name"]))  \(JSON.string(row["building"]))\(seatText)"
            }
            error = rooms.isEmpty ? "没有空教室" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}
