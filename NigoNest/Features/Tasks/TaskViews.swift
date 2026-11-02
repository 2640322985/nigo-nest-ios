import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

private struct Wish: Identifiable {
    let id = UUID()
    var title: String
    var target: [String: Any]
}

private struct GrabTask: Identifiable {
    var id: Int
    var title: String
    var status: String
    var when: String
}

struct CourseGrabView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var query = ""
    @State private var found: [[String: Any]] = []
    @State private var wishes: [Wish] = []
    @State private var weekdays: Set<Int> = []
    @State private var periods: Set<Int> = []
    @State private var password = ""
    @State private var executeAt = Date().addingTimeInterval(300)
    @State private var tasks: [GrabTask] = []
    @State private var logs: [Int: [String]] = [:]
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "自动抢课") {
            TextField("课程名", text: $query).inkField()
            InkButton(title: "搜索", filled: false) { Task { await search() } }
            ForEach(Array(found.enumerated()), id: \.offset) { _, course in
                InkRow(title: courseTitle(course)) { add(course) }
            }
            if !wishes.isEmpty {
                Text("已选课程").font(InkFont.title(18))
                ForEach(wishes) { wish in
                    HStack {
                        Text(wish.title).font(InkFont.body())
                        Spacer()
                        Button("移除") { wishes.removeAll { $0.id == wish.id } }
                            .foregroundStyle(Palette.ink)
                    }
                }
            }
            Text("只要这些星期，不选就是不限").font(InkFont.body(13))
            HStack {
                ForEach(1...7, id: \.self) { day in
                    InkChoice(title: ["一", "二", "三", "四", "五", "六", "日"][day - 1], selected: weekdays.contains(day)) {
                        if weekdays.contains(day) { weekdays.remove(day) } else { weekdays.insert(day) }
                    }
                }
            }
            Text("只要这些节次").font(InkFont.body(13))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(1...12, id: \.self) { period in
                        InkChoice(title: "\(period)", selected: periods.contains(period)) {
                            if periods.contains(period) { periods.remove(period) } else { periods.insert(period) }
                        }
                    }
                }
            }
            SecureField("教务密码，只用于这一次任务", text: $password).inkField()
            DatePicker("开始时间", selection: $executeAt, in: Date()...)
                .font(InkFont.body())
            InkButton(title: "创建任务") { Task { await create() } }
            StatusText(text: error)
            WavyDivider()
            ForEach(tasks) { task in
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title).font(InkFont.body())
                    Text("\(task.status)  \(task.when)").font(InkFont.body(13))
                    HStack {
                        Button("日志") { Task { await loadLogs(task.id) } }
                        if task.status != "cancelled" {
                            Button("取消") { Task { await cancel(task.id) } }
                        }
                        if task.status == "needs_auth" {
                            Button("重新授权") { Task { await reauthorize(task.id) } }
                        }
                    }
                    .font(InkFont.body(14))
                    .foregroundStyle(Palette.ink)
                    ForEach(logs[task.id] ?? [], id: \.self) { line in
                        Text(line).font(InkFont.body(13))
                    }
                }
                WavyDivider()
            }
        }
        .task { await reloadTasks() }
    }

    private func courseTitle(_ course: [String: Any]) -> String {
        let remain = JSON.int(course["remaining"])
        return "\(JSON.string(course["courseName"]))  \(JSON.string(course["teacherName"]))  余\(remain)"
    }

    private func add(_ course: [String: Any]) {
        let target = course["target"] as? [String: Any] ?? ["courseName": JSON.string(course["courseName"])]
        wishes.append(Wish(title: courseTitle(course), target: target))
    }

    private func search() async {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        do {
            let data = JSON.object(try await session.client.get("api/course-grab/courses?q=\(q)"))
            found = JSON.dictionaries(data["courses"])
            error = found.isEmpty ? "没有找到课程" : ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func create() async {
        guard !wishes.isEmpty else {
            error = "请先搜索并加入课程"
            return
        }
        let targets: [[String: Any]] = wishes.map { wish in
            var target = wish.target
            if !weekdays.isEmpty { target["weekdays"] = weekdays.sorted() }
            if !periods.isEmpty { target["periods"] = periods.sorted() }
            return target
        }
        let formatter = ISO8601DateFormatter()
        do {
            _ = try await session.client.post("api/course-grab/tasks", json: [
                "authToken": session.user?.token ?? "",
                "username": session.user?.studentId ?? "",
                "password": password,
                "executeAt": formatter.string(from: executeAt),
                "targets": targets,
            ])
            password = ""
            wishes = []
            await reloadTasks()
            error = "任务已创建"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func reloadTasks() async {
        do {
            let data = JSON.object(try await session.client.get("api/course-grab/tasks"))
            tasks = JSON.dictionaries(data["tasks"]).compactMap { row in
                let id = JSON.int(row["id"])
                guard id > 0, JSON.string(row["status"]) != "cancelled" else { return nil }
                let names = JSON.dictionaries(row["targets"]).map { JSON.string($0["courseName"]) }.joined(separator: "、")
                return GrabTask(id: id, title: names.isEmpty ? "任务 \(id)" : names, status: JSON.string(row["status"]), when: JSON.string(row["executeAt"]))
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func cancel(_ id: Int) async {
        do {
            _ = try await session.client.post("api/course-grab/tasks/\(id)/cancel", json: ["authToken": session.user?.token ?? ""])
            await reloadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func reauthorize(_ id: Int) async {
        do {
            _ = try await session.client.post("api/course-grab/tasks/\(id)/reauthorize", json: ["authToken": session.user?.token ?? ""])
            await reloadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadLogs(_ id: Int) async {
        do {
            let data = JSON.object(try await session.client.get("api/course-grab/tasks/\(id)/logs?afterId=0"))
            logs[id] = JSON.dictionaries(data["logs"]).map { JSON.string($0["message"]) }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct YxExamView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var papers: [[String: Any]] = []
    @State private var selected = ""
    @State private var draft: [String: Any] = [:]
    @State private var preview = ""
    @State private var submitAt = Date().addingTimeInterval(600)
    @State private var tasks: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "迎新答题") {
            ForEach(Array(papers.enumerated()), id: \.offset) { _, paper in
                InkChoice(title: JSON.string(paper["name"]), selected: selected == JSON.string(paper["key"])) {
                    selected = JSON.string(paper["key"])
                }
            }
            InkButton(title: "预览答案", filled: false) { Task { await previewPaper() } }
            if !preview.isEmpty { Text(preview).font(InkFont.body()) }
            DatePicker("交卷时间", selection: $submitAt, in: Date()...)
            InkButton(title: "安排交卷") { Task { await schedule() } }
            StatusText(text: error)
            ForEach(tasks, id: \.self) { task in
                Text(task).font(InkFont.body(14))
                WavyDivider()
            }
            InkButton(title: "取消最近一条", filled: false) { Task { await cancelLatest() } }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let data = JSON.object(try await session.client.get("api/yx-exam/papers"))
            papers = JSON.dictionaries(data["papers"])
            selected = JSON.string(papers.first?["key"])
            let taskData = JSON.object(try await session.client.get("api/yx-exam/tasks"))
            tasks = JSON.dictionaries(taskData["tasks"]).map { row in
                "\(JSON.int(row["id"]))  \(JSON.string(row["examName"]))  \(JSON.string(row["status"]))  \(JSON.string(row["resultMessage"]))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func previewPaper() async {
        do {
            let data = JSON.object(try await session.client.post("api/yx-exam/preview", json: [
                "authToken": session.user?.token ?? "",
                "examKey": selected,
            ]))
            draft = data["draft"] as? [String: Any] ?? [:]
            let view = data["preview"] as? [String: Any] ?? [:]
            preview = "预计 \(JSON.int(view["estimatedScore"])) 分，及格线 \(JSON.int(view["passScore"]))，未匹配 \(JSON.int(view["missCount"])) 题"
            error = ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func schedule() async {
        guard !draft.isEmpty else {
            error = "请先预览"
            return
        }
        do {
            _ = try await session.client.post("api/yx-exam/schedule", json: [
                "authToken": session.user?.token ?? "",
                "draft": draft,
                "submitAt": ISO8601DateFormatter().string(from: submitAt),
            ])
            await load()
            error = "已安排"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func cancelLatest() async {
        guard let id = tasks.first?.split(separator: " ").first, let taskId = Int(id) else { return }
        do {
            _ = try await session.client.post("api/yx-exam/cancel", json: [
                "authToken": session.user?.token ?? "",
                "taskId": taskId,
            ])
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SafetyExamView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var sessionId = ""
    @State private var captchaImage = ""
    @State private var captcha = ""
    @State private var password = ""
    @State private var papers: [[String: Any]] = []
    @State private var tasks: [String] = []
    @State private var error = ""

    var body: some View {
        PageScaffold(title: "安全知识考试") {
            if let image = CaptchaImage.decode(captchaImage) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .onTapGesture { Task { await loadCaptcha() } }
            }
            SecureField("考试系统密码", text: $password).inkField()
            TextField("验证码", text: $captcha).inkField()
            InkButton(title: "登录考试系统", filled: false) { Task { await login() } }
            ForEach(Array(papers.enumerated()), id: \.offset) { _, paper in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(JSON.string(paper["name"]))  \(JSON.bool(paper["passed"]) ? "已通过" : "未通过")")
                        .font(InkFont.body())
                    if !JSON.bool(paper["passed"]) {
                        Button("开始") { Task { await start(JSON.string(paper["id"])) } }
                            .font(InkFont.body())
                            .foregroundStyle(Palette.ink)
                    }
                }
                WavyDivider()
            }
            ForEach(tasks, id: \.self) { task in
                Text(task).font(InkFont.body(14))
            }
            InkButton(title: "取消最近一条", filled: false) { Task { await cancelLatest() } }
            StatusText(text: error)
        }
        .task {
            await loadCaptcha()
            await loadTasks()
        }
    }

    private func loadCaptcha() async {
        do {
            let data = JSON.object(try await session.client.get("api/bwcks/captcha"))
            sessionId = JSON.string(data["sessionId"])
            captchaImage = JSON.string(data["captcha"])
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func login() async {
        do {
            let data = JSON.object(try await session.client.post("api/bwcks/login", json: [
                "authToken": session.user?.token ?? "",
                "sessionId": sessionId,
                "password": password,
                "captcha": captcha,
            ]))
            if JSON.bool(data["needChangePwd"]) {
                error = "学校要求先修改考试系统密码"
                return
            }
            papers = JSON.dictionaries(data["papers"])
            let next = JSON.string(data["sessionId"])
            if !next.isEmpty { sessionId = next }
            error = ""
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
            await loadCaptcha()
        }
    }

    private func start(_ ksmk: String) async {
        do {
            let data = JSON.object(try await session.client.post("api/bwcks/start", json: [
                "authToken": session.user?.token ?? "",
                "sessionId": sessionId,
                "ksmk": ksmk,
            ]))
            error = JSON.string(data["message"], fallback: "已开始，到时间会自动交卷")
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTasks() async {
        guard let raw = try? await session.client.get("api/bwcks/tasks") else { return }
        tasks = JSON.dictionaries(JSON.object(raw)["tasks"]).map { row in
            "\(JSON.int(row["id"]))  \(JSON.string(row["examName"]))  \(JSON.string(row["status"]))  \(JSON.string(row["resultMessage"]))"
        }
    }

    private func cancelLatest() async {
        guard let id = tasks.first?.split(separator: " ").first, let taskId = Int(id) else { return }
        do {
            _ = try await session.client.post("api/bwcks/cancel", json: [
                "authToken": session.user?.token ?? "",
                "taskId": taskId,
            ])
            await loadTasks()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private enum CaptchaImage {
    static func decode(_ raw: String) -> UIImage? {
        let payload = raw.components(separatedBy: ",").last ?? raw
        guard let data = Data(base64Encoded: payload) else { return nil }
        return UIImage(data: data)
    }
}

struct AccountView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var nickname = ""
    @State private var error = ""
    @State private var photo: PhotosPickerItem?

    var body: some View {
        PageScaffold(title: "账号") {
            PhotosPicker(selection: $photo, matching: .images) {
                InkAvatar(url: session.user?.avatarUrl, size: 72)
            }
            .onChange(of: photo) { _, item in
                Task { await upload(item) }
            }
            Text(session.user?.studentId ?? "").font(InkFont.body(14))
            TextField("昵称，2 到 12 个字", text: $nickname).inkField()
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
            session.apply(nickname: nickname)
            error = "已保存"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func upload(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let picked = try await item.loadTransferable(type: PickedImage.self) else { return }
            let data = JSON.object(try await session.client.post("api/user/avatar", json: [
                "authToken": session.user?.token ?? "",
                "studentId": session.user?.studentId ?? "",
                "imageBase64": picked.data.base64EncodedString(),
                "mimeType": "image/jpeg",
            ]))
            session.apply(avatarUrl: JSON.string(data["avatarUrl"]))
            error = "头像已更新"
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct PickedImage: Transferable {
    var data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedImage(data: data)
        }
    }
}
