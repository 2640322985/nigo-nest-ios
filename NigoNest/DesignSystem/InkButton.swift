import SwiftUI

struct InkButton: View {
    var title: String
    var filled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkFont.body(16))
                .foregroundStyle(filled ? Palette.paper : Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(filled ? Palette.ink : Palette.paper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.ink, lineWidth: filled ? 0 : 4)
                )
        }
        .buttonStyle(.plain)
    }
}

struct InkRow: View {
    var title: String
    var badge: Int = 0
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(InkFont.body())
                    .foregroundStyle(Palette.ink)
                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(InkFont.body(12))
                        .foregroundStyle(Palette.paper)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Palette.ink, in: Capsule())
                }
                Spacer()
                Text(">")
                    .font(InkFont.body())
                    .rotationEffect(.degrees(8))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct InkChoice: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InkFont.body(14))
                .foregroundStyle(selected ? Palette.paper : Palette.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Palette.ink : Palette.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.ink, lineWidth: selected ? 0 : 2))
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func inkField() -> some View {
        font(InkFont.body())
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink, lineWidth: 3))
    }
}
