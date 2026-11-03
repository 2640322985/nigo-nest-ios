import SwiftUI

struct CampusArtwork: View {
    var name: String
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Image(name).resizable().scaledToFit()
            .padding(4)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if scheme == .dark {
                    RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2), lineWidth: 1)
                }
            }
            .accessibilityHidden(true)
    }
}

struct CampusSection: View {
    var title: String
    var detail: String = ""
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.custom("MaShanZheng-Regular", size: 25, relativeTo: .title2))
            Spacer()
            if !detail.isEmpty { Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct CampusLink: View {
    var title: String
    var icon: String
    var badge: Int = 0
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon).font(.system(size: 19)).frame(width: 25)
                Text(title).font(.body)
                Spacer()
                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)").font(.caption2.bold())
                        .padding(5).foregroundStyle(Palette.paper)
                        .background(Palette.ink, in: Capsule())
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.foregroundStyle(Palette.ink).padding(.vertical, 15).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct CampusGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 15)
            .background(Palette.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
    }
}
