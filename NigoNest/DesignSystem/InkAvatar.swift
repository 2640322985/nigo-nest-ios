import SwiftUI

struct InkAvatar: View {
    var url: String? = nil
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Palette.ink, lineWidth: 3)
            if let url, url.hasPrefix("http"), let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
                .frame(width: size - 8, height: size - 8)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("头像")
    }

    private var placeholder: some View {
        Circle()
            .stroke(Palette.ink, lineWidth: 2.5)
            .frame(width: size * 0.34, height: size * 0.34)
            .offset(y: -size * 0.06)
    }
}
