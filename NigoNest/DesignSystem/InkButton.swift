import SwiftUI

struct InkButton: View {
    @ThemePalette private var palette
    var title: String
    var filled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkFont.body(16))
                .foregroundStyle(filled ? palette.onAccent : palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(filled ? palette.accent : palette.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.ink, lineWidth: filled ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct InkRow: View {
    @ThemePalette private var palette
    var title: String
    var badge: Int = 0
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(InkFont.body())
                    .foregroundStyle(palette.ink)
                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(InkFont.body(12))
                        .foregroundStyle(palette.paper)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(palette.ink, in: Capsule())
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct InkChoice: View {
    @ThemePalette private var palette
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkFont.body(14))
                .foregroundStyle(selected ? palette.onAccent : palette.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? palette.accent : palette.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(palette.ink, lineWidth: selected ? 0 : 2))
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func inkField() -> some View { modifier(InkFieldStyle()) }
}

private struct InkFieldStyle: ViewModifier {
    @ThemePalette private var palette
    func body(content: Content) -> some View {
        content.font(InkFont.body()).padding(12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.rule, lineWidth: 0.75))
    }
}
