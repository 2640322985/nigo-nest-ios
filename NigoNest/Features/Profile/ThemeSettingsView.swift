import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.campusTheme) private var active
    @ThemePalette private var palette
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                InkTitle(text: "换一种校园心情。", size: 30)
                Text("选择喜欢的外观，内容与功能照常。主题会跟随系统切换深浅色。")
                    .font(.subheadline).foregroundStyle(.secondary)
                ForEach(AppTheme.allCases) { theme in
                    Button { ThemePreference.save(theme) } label: {
                        VStack(alignment: .leading, spacing: 15) {
                            ThemePreviewCard().environment(\.campusTheme, theme)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.title).font(.headline)
                                    Text(theme.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: active == theme ? "checkmark.circle.fill" : "circle")
                                    .font(.title2).foregroundStyle(active == theme ? palette.accent : .secondary)
                            }
                        }.padding(16).foregroundStyle(palette.ink)
                            .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(active == theme ? palette.accent : palette.rule, lineWidth: active == theme ? 1.5 : 0.75))
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("theme-\(theme.rawValue)")
                        .accessibilityLabel(theme.title)
                        .accessibilityValue(active == theme ? "已选择" : "未选择")
                        .accessibilityHint("立即应用并保存主题")
                }
            }.padding(20)
        }.background(ThemePaper())
            .navigationTitle("主题外观").navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemePreviewCard: View {
    @ThemePalette private var palette
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                Text("今天，去上课。").font(.custom("MaShanZheng-Regular", size: 25))
                Text("高等数学").font(.headline)
                Label("同和楼 A203", systemImage: "mappin").font(.caption).foregroundStyle(palette.blue)
                Capsule().fill(palette.accent).frame(width: 54, height: 4)
            }.frame(maxWidth: .infinity, alignment: .leading)
            CampusArtwork(name: "CampusWalking").frame(width: 66, height: 98)
        }.padding(14).foregroundStyle(palette.ink)
            .background(palette.note, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.rule, lineWidth: 0.75))
    }
}
