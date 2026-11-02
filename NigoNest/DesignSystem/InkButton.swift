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
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(InkFont.body())
                    .foregroundStyle(Palette.ink)
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

extension View {
    func inkField() -> some View {
        font(InkFont.body())
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink, lineWidth: 3))
    }
}
