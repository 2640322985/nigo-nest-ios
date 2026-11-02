import SwiftUI

struct CourseGrabView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var query = ""
    @State private var found: [[String: Any]] = []
    @State private var tasks: [String] = []
    @State private var password = ""
    @State private var when = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "抢课") {
            TextField("课程名", text: $query).inkField()
            InkButton(title: "搜索", filled: false) { Task { await search() } }
            TextField("教务密码，只用于这一次任务", text: $password).inkField()
            TextField("执行时间 2026-11-03 08:00", text: $when).inkField()
            StatusText(text: error)
            ForEach(Array(found.enumerated()), id: \.offset) { index, course in
                InkRow(title: JSON.string(course["courseName"])) {
                    Task { await create(course) }
                }
                .id(index)
            }
            WavyDivider()
            ForEach(tasks, id: \.self) { task in
                Text(task).font(InkFont.body(14))
            }
        }
        .task { await reloadTasks() }
    }

    private func search() async {
        do {
            let data = JSON.object(try await session.client.get("api/course-grab/courses?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"))
            found = JSON.dictionaries(data["courses"])
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func create(_ course: [String: Any]) async {
        let target = course["target"] as? [String: Any] ?? ["courseName": JSON.string(course["courseName"])]
        do {
            _ = try await session.client.post("api/course-grab/tasks", json: [
                "authToken": session.user?.token ?? "",
                "username": session.user?.studentId ?? "",
                "password": password,
                "executeAt": when,
                "targets": [target],
            ])
            await reloadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func reloadTasks() async {
        do {
            let data = JSON.object(try await session.client.get("api/course-grab/tasks"))
            tasks = JSON.dictionaries(data["tasks"]).map { row in
                "\(JSON.string(row["status"]))  \(JSON.string(row["resultMessage"]))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct YxExamView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var papers: [String] = []
    @State private var tasks: [String] = []
    @State private var examKey = ""
    @State private var score = "80"
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "迎新答题") {
            StatusText(text: error)
            ForEach(papers, id: \.self) { paper in
                Text(paper).font(InkFont.body())
            }
            TextField("试卷编号", text: $examKey).inkField()
            TextField("目标分", text: $score).inkField()
            InkButton(title: "预览并安排交卷") { Task { await schedule() } }
            ForEach(tasks, id: \.self) { task in
                Text(task).font(InkFont.body(14))
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/yx-exam/papers"))
            papers = JSON.dictionaries(data["papers"]).map {
                "\(JSON.string($0["examKey"], fallback: JSON.string($0["key"])))  \(JSON.string($0["title"], fallback: JSON.string($0["name"])))"
            }
            let taskData = JSON.object(try await session.client.get("api/yx-exam/tasks"))
            tasks = JSON.dictionaries(taskData["tasks"]).map {
                "\(JSON.int($0["id"]))  \(JSON.string($0["status"]))  \(JSON.string($0["resultMessage"]))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func schedule() async {
        do {
            let preview = JSON.object(try await session.client.post("api/yx-exam/preview", json: [
                "authToken": session.user?.token ?? "",
                "examKey": examKey,
                "targetScore": Int(score) ?? 80,
            ]))
            guard let draft = preview["draft"] else {
                error = "没有可交的答卷"
                return
            }
            _ = try await session.client.post("api/yx-exam/schedule", json: [
                "authToken": session.user?.token ?? "",
                "draft": draft,
            ])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SafetyExamView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var tasks: [String] = []
    @State private var ksmk = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "安全考试") {
            TextField("科目编号", text: $ksmk).inkField()
            InkButton(title: "查看任务") { Task { await load() } }
            InkButton(title: "取消最近一条", filled: false) { Task { await cancelLatest() } }
            StatusText(text: error)
            ForEach(tasks, id: \.self) { task in
                Text(task).font(InkFont.body())
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/bwcks/tasks"))
            tasks = JSON.dictionaries(data["tasks"]).map { row in
                "\(JSON.int(row["id"]))  \(JSON.string(row["status"]))  \(JSON.string(row["resultMessage"]))"
            }
            if tasks.isEmpty { error = "还没有安全考试任务" } else { error = "" }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func cancelLatest() async {
        guard let id = tasks.first?.split(separator: " ").first, let taskId = Int(id) else { return }
        do {
            _ = try await session.client.post("api/bwcks/cancel", json: [
                "authToken": session.user?.token ?? "",
                "taskId": taskId,
            ])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct AccountView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var nickname = ""
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "账号") {
            InkAvatar(url: session.user?.avatarUrl, size: 72)
            Text(session.user?.studentId ?? "").font(InkFont.body(14))
            TextField("昵称", text: $nickname).inkField()
            InkButton(title: "保存昵称") { Task { await save() } }
            StatusText(text: error)
        }
        .onAppear { nickname = session.user?.nickname ?? "" }
    }

    private func save() async {
        do {
            _ = try await session.client.post("api/user/nickname", json: [
                "authToken": session.user?.token ?? "",
                "nickname": nickname,
            ])
            error = "已保存"
        } catch {
            self.error = error.localizedDescription
        }
    }
}
