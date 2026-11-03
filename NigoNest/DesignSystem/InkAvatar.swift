import SwiftUI

struct InkAvatar: View {
    @ThemePalette private var palette
    var url: String? = nil
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(palette.surface)
            Circle().stroke(palette.rule, lineWidth: 1)
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
        Group {
          if palette.isJournal {
            Image("JournalCat").resizable().scaledToFit().padding(size * 0.09)
          } else {
            Image(systemName: "person.crop.circle")
            .font(.system(size: size * 0.68, weight: .ultraLight))
            .foregroundStyle(palette.ink)
          }
        }
    }
}
