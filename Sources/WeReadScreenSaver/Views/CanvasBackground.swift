import SwiftUI

struct CanvasBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.92),
                    Color(red: 0.91, green: 0.93, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.35),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 30,
                endRadius: 760
            )

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.white.opacity(0.18))
                .blur(radius: 50)
                .offset(x: -220, y: -180)

            GrainOverlay()
                .blendMode(.overlay)
                .opacity(0.22)
        }
        .ignoresSafeArea()
    }
}

private struct GrainOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 26
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let alpha = Double(((Int(x + y) % 11) + 1)) / 160.0
                    let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                    context.fill(Path(rect), with: .color(.black.opacity(alpha)))
                    x += step
                }
                y += step
            }
        }
    }
}
