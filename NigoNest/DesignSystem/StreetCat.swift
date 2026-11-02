import SwiftUI

/// 页头点缀。圆头、圆肩、无五官，只有一个黑点。
struct StreetCat: View {
    var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(Palette.ink)
            var head = Path(ellipseIn: CGRect(x: size.width * 0.28, y: 0, width: size.width * 0.44, height: size.width * 0.44))
            context.stroke(head, with: ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            var body = Path(ellipseIn: CGRect(x: size.width * 0.12, y: size.height * 0.38, width: size.width * 0.76, height: size.height * 0.5))
            context.fill(body, with: ink)
            let eye = CGRect(x: size.width * 0.46, y: size.width * 0.16, width: 5, height: 5)
            context.fill(Path(ellipseIn: eye), with: ink)
        }
        .frame(width: 72, height: 64)
        .accessibilityLabel("小猫")
    }
}
