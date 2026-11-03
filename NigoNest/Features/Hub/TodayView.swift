import SwiftUI

struct TodayView: View {
    @ThemePalette private var palette
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nav: AppNav
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var courses: [CampusCourse] = []
    @State private var features = FeatureFlags()
    private var today: [CampusCourse] {
        courses.filter { $0.weekday == CampusSchedule.weekday(session.displayDate) }
            .sorted { $0.start < $1.start }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                InkTitle(text: "今天，也很充实。", size: 30)
                HStack {
                    Text(session.displayDate.formatted(Date.FormatStyle(date: .complete, time: .omitted, locale: Locale(identifier: "zh_CN"), timeZone: TimeZone(identifier: "Asia/Shanghai")!)))
                    Spacer()
                    if session.isPreview { Text("演示数据").foregroundStyle(.secondary) }
                }.font(.caption)

                focusCard
                CampusSection(title: "校园工具")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 16) {
                    tool("课表", "calendar", .schedule)
                    if features.emptyClassroom { tool("空教室", "chair", .classroom) }
                    tool("场馆预约", "sportscourt", .venue)
                    tool("签到", "checkmark.circle", .checkin)
                    if features.courseGrab { tool("抢课", "bolt", .grab) }
                    if showYx { tool("迎新", "graduationcap", .yx) }
                    if showSafety { tool("安全考试", "checkmark.shield", .safety) }
                    tool("建议", "bubble.left", .suggestions)
                }
                CampusSection(title: "一天的安排", detail: today.isEmpty ? "" : "共 \(today.count) 门课")
                if today.isEmpty {
                    ContentUnavailableView("今天没有课程", systemImage: "calendar", description: Text(courses.isEmpty ? "从教务导入课表后，这里会显示当天安排。" : "留点时间，做自己喜欢的事。"))
                    Button("查看或导入课表") { nav.open(.schedule) }.officialAction(prominent: false)
                } else {
                    ForEach(Array(today.enumerated()), id: \.element.id) { index, course in
                        agenda(course, focused: index == 0)
                    }
                }
                Text("慢慢来，也很好。").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }.padding(20)
        }
        .background(ThemePaper())
        .navigationTitle("泥工小窝").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("消息通知", systemImage: "bell") { nav.open(.notifications) }
            }
        }
        .task { await reload() }
        .onAppear { courses = CampusSchedule.load(student: session.user?.studentId ?? "") }
    }

    private var focusCard: some View {
        Button { nav.open(.schedule) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(today.isEmpty ? "校园日常" : "今日首课").font(.caption.weight(.medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.footnote)
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(today.first?.name ?? "新的一天，慢慢来。")
                            .font(.title3.bold()).fixedSize(horizontal: false, vertical: true)
                        if let course = today.first {
                            Text(course.place.isEmpty ? "教室待确认" : course.place).font(.title2.bold())
                            Text("第 \(course.start)–\(course.end) 节").font(.title3.monospacedDigit())
                        } else {
                            Text("课表、运动，还有同学们的小事。").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    if !typeSize.isAccessibilitySize {
                        CampusArtwork(name: "CampusWalking").frame(width: 90, height: 140)
                    }
                }
                Text("查看完整课表").font(.caption).foregroundStyle(.secondary)
            }.padding(16).foregroundStyle(palette.ink)
                .background {
                    RoundedRectangle(cornerRadius: 18).fill(palette.note)
                    if palette.isJournal { NotebookLines().clipShape(RoundedRectangle(cornerRadius: 18)) }
                }
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.ink, lineWidth: 1))
                .overlay(alignment: .topLeading) { if palette.isJournal { JournalTape() } }
        }.buttonStyle(.plain)
    }

    private var showYx: Bool {
        features.yxExam && (session.user?.studentId.hasPrefix("2026") == true)
    }

    private var showSafety: Bool {
        features.safetyExam && (session.user?.studentId.hasPrefix("2026") == true)
    }

    private func reload() async {
        courses = CampusSchedule.load(student: session.user?.studentId ?? "")
        #if DEBUG
        if session.isPreview { courses = PreviewFixtures.courses }
        #endif
        guard let raw = try? await session.client.get("api/app/features") else { return }
        let src = JSON.object(raw)
        let flags = src["features"] as? [String: Any] ?? src
        features = FeatureFlags(
            courseGrab: flags["courseGrab"] == nil ? true : JSON.bool(flags["courseGrab"]),
            yxExam: flags["yxExam"] == nil ? true : JSON.bool(flags["yxExam"]),
            safetyExam: flags["safetyExam"] == nil ? true : JSON.bool(flags["safetyExam"]),
            emptyClassroom: flags["emptyClassroom"] == nil ? true : JSON.bool(flags["emptyClassroom"]),
            chuanggaoRun: JSON.bool(flags["chuanggaoRun"])
        )
    }

    private func tool(_ title: String, _ icon: String, _ route: AppRoute) -> some View {
        Button { nav.open(route) } label: {
            VStack(spacing: 9) {
                Image(systemName: icon).font(.system(size: 24, weight: .light))
                    .foregroundStyle(palette.isJournal ? (route == .schedule || route == .classroom ? palette.blue : palette.accent) : palette.ink)
                Text(title).font(.caption)
            }.frame(maxWidth: .infinity, minHeight: 58).contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(palette.ink)
    }

    private func agenda(_ course: CampusCourse, focused: Bool) -> some View {
        Button { nav.open(.schedule) } label: {
            HStack(spacing: 14) {
                Text("\(course.start)–\(course.end)节").font(.subheadline.monospacedDigit())
                VStack(alignment: .leading, spacing: 5) {
                    Text(course.name).font(.headline)
                    Text(course.place.isEmpty ? "教室待确认" : course.place).font(.caption)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.caption)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(focused && !palette.isJournal ? palette.paper : palette.ink)
                .background(focused && !palette.isJournal ? palette.ink : palette.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if palette.isJournal { RoundedRectangle(cornerRadius: 12).stroke(palette.blue.opacity(0.2), lineWidth: 0.75) }
                }
        }.buttonStyle(.plain)
    }
}
