import SwiftUI

struct CoverCardView: View {
    let item: ShelfItem
    let index: Int

    var body: some View {
        let phase = Double((index % 7)) * 0.6
        let tilt = sin(phase) * 1.4
        let scale = 1.0 + (cos(phase) * 0.015)

        VStack(alignment: .leading, spacing: 8) {
            CoverArtView(item: item)
                .frame(maxWidth: .infinity)
                .aspectRatio(0.74, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
                .rotationEffect(.degrees(tilt))
                .scaleEffect(scale)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                    .lineLimit(1)

                Text(item.author)
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundStyle(.black.opacity(0.48))
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .padding(4)
    }
}

private struct CoverArtView: View {
    let item: ShelfItem

    var body: some View {
        ZStack {
            baseFill

            if let coverURL = item.coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty:
                        PlaceholderCover(item: item)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        PlaceholderCover(item: item)
                    @unknown default:
                        PlaceholderCover(item: item)
                    }
                }
            } else {
                PlaceholderCover(item: item)
            }
        }
        .clipped()
    }

    private var baseFill: some View {
        LinearGradient(
            colors: palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var palette: [Color] {
        switch item.kind {
        case .book:
            return [
                Color(red: 0.96, green: 0.95, blue: 0.92),
                Color(red: 0.84, green: 0.89, blue: 0.96)
            ]
        case .album:
            return [
                Color(red: 0.97, green: 0.94, blue: 0.87),
                Color(red: 0.88, green: 0.90, blue: 0.96)
            ]
        }
    }
}

private struct PlaceholderCover: View {
    let item: ShelfItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.kind == .album ? "AUDIO" : "BOOK")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(.black.opacity(0.30))

                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.80))
                    .lineLimit(3)

                Text(item.author)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.black.opacity(0.40))
                    .lineLimit(1)
            }
            .padding(14)
        }
    }

    private var colors: [Color] {
        let seed = abs(item.id.hashValue)
        let hue = Double(seed % 360) / 360.0
        let hue2 = Double((seed / 7) % 360) / 360.0
        return [
            Color(hue: hue, saturation: 0.10, brightness: 0.97),
            Color(hue: hue2, saturation: 0.14, brightness: 0.90)
        ]
    }
}
