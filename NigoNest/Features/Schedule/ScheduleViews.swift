import SwiftUI

struct ScheduleCourseRow: Identifiable {
    let id: String
    var name: String
    var detail: String
    var noteKey: String
}

struct ScheduleView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var courses: [ScheduleCourseRow] = []
    @State private var term = ""
    @State private var xnm = ""
    @State private var xqm = ""
    @State private var error = ""
    @State private var noteKey = ""
    @State private var note = ""

    var body: some View {
        PageScaffold(title: "课表") {
            Text(term.isEmpty ? "还没有课表" : term).font(InkFont.body(14))
            StatusText(text: error)
            InkButton(title: "从教务导入") { Task { await importSchedule() } }
            ForEach(courses) { course in
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name).font(InkFont.title(18))
                    Text(course.detail).font(InkFont.body(14))
                }
                .onTapGesture {
                    noteKey = course.noteKey
                    note = ""
                }
                WavyDivider()
            }
            if !noteKey.isEmpty {
                Text("备注").font(InkFont.title(18))
                TextField("这节课要做的事", text: $note, axis: .vertical)
                    .font(InkFont.body())
                    .padding(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink, lineWidth: 3))
                InkButton(title: "保存备注") { Task { await saveNote() } }
            }
        }
    }

    private func importSchedule() async {
        do {
            let data = JSON.object(try await session.client.post("api/schedule/import", json: [
                "authToken": session.user?.token ?? "",
            ]))
            let schedule = data["schedule"] as? [String: Any] ?? [:]
            xnm = JSON.string(schedule["xnm"])
            xqm = JSON.string(schedule["xqm"])
            term = JSON.string(schedule["termLabel"])
            courses = JSON.dictionaries(schedule["courses"]).enumerated().map { index, row in
                let name = JSON.string(row["name"])
                let weekday = JSON.int(row["weekday"], fallback: 1)
                let sections = JSON.dictionaries(row["sections"])
                let start = JSON.int(sections.first?["start"], fallback: 1)
                let end = JSON.int(sections.first?["end"], fallback: start)
                let identity = JSON.string(row["id"]).split(separator: "|").first.map(String.init) ?? name
                let key = "\(identity)|\(weekday)|\(start)-\(end)"
                let place = JSON.string(row["location"])
                return ScheduleCourseRow(
                    id: "\(key)-\(index)",
                    name: name,
                    detail: "周\(weekday)  \(start)-\(end) 节  \(place)",
                    noteKey: key
                )
            }
            if let first = courses.first {
                let defaults = UserDefaults(suiteName: "group.com.nigo.nest")
                defaults?.set(first.name, forKey: "widget.course")
                defaults?.set(first.detail, forKey: "widget.time")
            }
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func saveNote() async {
        do {
            _ = try await session.client.post("api/schedule/notes", json: [
                "authToken": session.user?.token ?? "",
                "xnm": xnm,
                "xqm": xqm,
                "courseKey": noteKey,
                "text": note,
            ])
            error = "备注已保存"
            let defaults = UserDefaults(suiteName: "group.com.nigo.nest")
            defaults?.set(note, forKey: "widget.note")
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ClassroomView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var campusId = ""
    @State private var building = ""
    @State private var rooms: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "空教室") {
            TextField("校区编号，可留空", text: $campusId).inkField()
            TextField("楼栋，可留空", text: $building).inkField()
            InkButton(title: "查询") { Task { await query() } }
            StatusText(text: error)
            ForEach(rooms, id: \.self) { room in
                Text(room).font(InkFont.body())
            }
        }
    }

    private func query() async {
        var json: [String: Any] = ["authToken": session.user?.token ?? ""]
        if !campusId.isEmpty { json["campusId"] = campusId }
        if !building.isEmpty { json["building"] = building }
        do {
            let data = JSON.object(try await session.client.post("api/classroom/empty", json: json))
            rooms = JSON.dictionaries(data["rooms"]).map { row in
                "\(JSON.string(row["name"]))  \(JSON.string(row["building"]))"
            }
            error = rooms.isEmpty ? "没有空教室" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }
}
