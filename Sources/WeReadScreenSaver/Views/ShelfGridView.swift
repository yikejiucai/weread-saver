import SwiftUI

struct ShelfGridView: View {
    let items: [ShelfItem]
    let sourceLabel: String

    private let layout = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("微信读书书架")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.82))

                    Text(sourceLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.black.opacity(0.42))
                }

                Spacer()

                Text("\(items.count)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.42))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.7), in: Capsule())
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: layout, spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        CoverCardView(item: item, index: index)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }
}
