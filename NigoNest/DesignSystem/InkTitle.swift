import SwiftUI

struct InkTitle: View {
    var text: String
    var size: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(InkFont.title(size + (index % 3 == 0 ? 2 : 0)))
                        .rotationEffect(.degrees(index % 2 == 0 ? -2.5 : 2))
                        .offset(y: index % 2 == 0 ? 1 : -1)
                }
            }
            .foregroundStyle(Palette.ink)
            WobblyUnderline()
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1, 0]))
                .frame(height: 8)
        }
    }
}

struct WobblyUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midY
        path.move(to: CGPoint(x: 0, y: mid))
        var x: CGFloat = 0
        while x < rect.width {
            let next = min(x + 14, rect.width)
            path.addQuadCurve(
                to: CGPoint(x: next, y: mid),
                control: CGPoint(x: x + 7, y: mid + (Int(x / 14) % 2 == 0 ? -3 : 3))
            )
            x = next
        }
        return path
    }
}

struct WavyDivider: View {
    var body: some View {
        WavyLine()
            .stroke(Palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 6]))
            .frame(height: 14)
            .padding(.vertical, 8)
    }
}

struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midY
        path.move(to: CGPoint(x: 0, y: mid))
        var x: CGFloat = 0
        while x < rect.width {
            let next = min(x + 18, rect.width)
            path.addQuadCurve(
                to: CGPoint(x: next, y: mid),
                control: CGPoint(x: x + 9, y: mid + (Int(x / 18) % 2 == 0 ? -5 : 5))
            )
            x = next
        }
        return path
    }
}
