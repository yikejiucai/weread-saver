import SwiftUI

struct RootView: View {
    @ObservedObject var store: ShelfStore
    let onExitRequested: () -> Void
    var showsExitButton: Bool = true

    var body: some View {
        ZStack {
            CanvasBackground()

            switch store.state {
            case .loading:
                ShelfGridView(items: store.items, sourceLabel: store.sourceLabel)
                    .redacted(reason: .placeholder)
                OverlayBadge(text: "正在读取书架")
            case .loaded, .empty:
                ShelfGridView(items: store.items, sourceLabel: store.sourceLabel)
                if store.items.isEmpty {
                    EmptyStateView()
                }
            case .failed(let message):
                ShelfGridView(items: store.items, sourceLabel: store.sourceLabel)
                EmptyStateView(message: message)
            }
        }
        .overlay(alignment: .topTrailing) {
            if showsExitButton {
                ExitButton(action: onExitRequested)
                    .padding(24)
            }
        }
        .animation(.easeOut(duration: 0.35), value: store.items)
        .animation(.easeOut(duration: 0.25), value: store.state)
    }
}

private struct ExitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("退出")
                .font(.system(size: 12, weight: .medium, design: .default))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.7))
    }
}

private struct OverlayBadge: View {
    let text: String

    var body: some View {
        VStack {
            HStack {
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.22), in: Capsule())
                Spacer()
            }
            .padding(24)
            Spacer()
        }
    }
}
