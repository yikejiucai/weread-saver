import SwiftUI

struct EmptyStateView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "books.vertical")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.black.opacity(0.32))

            Text("书架暂时没有内容")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black.opacity(0.72))

            if let message {
                Text(message)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.black.opacity(0.40))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .padding(28)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 12)
    }
}
