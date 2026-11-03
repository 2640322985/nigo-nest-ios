import SwiftUI

struct InkTitle: View {
    var text: String
    var size: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.custom("MaShanZheng-Regular", size: size, relativeTo: .title))
            .foregroundStyle(Palette.ink)
            WobblyUnderline()
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: min(size * 4.5, 180), height: 5)
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
        Rectangle().fill(Palette.rule).frame(height: 0.5).padding(.vertical, 14)
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
