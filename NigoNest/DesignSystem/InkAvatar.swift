import SwiftUI

struct InkAvatar: View {
    var url: String? = nil
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(Palette.surface)
            Circle().stroke(Palette.rule, lineWidth: 1)
            if let url, url.hasPrefix("http"), let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
                .frame(width: size - 8, height: size - 8)
                .clipShape(Circle())
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("头像")
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: size * 0.68, weight: .ultraLight))
            .foregroundStyle(Palette.ink)
    }
}
