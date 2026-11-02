import WidgetKit
import SwiftUI

struct ClassEntry: TimelineEntry {
    let date: Date
    let course: String
    let timeText: String
    let note: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ClassEntry {
        ClassEntry(date: Date(), course: "下一节课", timeText: "", note: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassEntry>) -> Void) {
        let entry = load()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func load() -> ClassEntry {
        let defaults = UserDefaults(suiteName: "group.com.nigo.nest")
        return ClassEntry(
            date: Date(),
            course: defaults?.string(forKey: "widget.course") ?? "打开泥工小窝同步课表",
            timeText: defaults?.string(forKey: "widget.time") ?? "",
            note: defaults?.string(forKey: "widget.note") ?? ""
        )
    }
}

struct ClassWidgetView: View {
    var entry: ClassEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.course)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.07))
                .lineLimit(2)
            Text(entry.timeText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color.white, for: .widget)
    }
}

struct NextClassWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextClass", provider: Provider()) { entry in
            ClassWidgetView(entry: entry)
        }
        .configurationDisplayName("下一节课")
        .description("显示当前课程、时间和备注")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct NigoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextClassWidget()
    }
}
