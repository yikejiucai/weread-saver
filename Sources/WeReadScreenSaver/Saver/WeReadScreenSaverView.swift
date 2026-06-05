import AppKit
import ScreenSaver
import SwiftUI

@MainActor
@objc(WeReadScreenSaverView)
final class WeReadScreenSaverView: ScreenSaverView {
    private let store = ShelfStore(
        provider: ChromeBrowserShelfProvider(
            fallback: SampleShelfProvider.sample()
        )
    )
    private var hostingView: NSHostingView<RootView>?
    private var refreshTask: Task<Void, Never>?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        refreshTask?.cancel()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        animationTimeInterval = 1.0 / 30.0

        let rootView = RootView(
            store: store,
            onExitRequested: {},
            showsExitButton: false
        )

        let host = NSHostingView(rootView: rootView)
        host.translatesAutoresizingMaskIntoConstraints = false
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(host)

        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingView = host
    }

    override func startAnimation() {
        super.startAnimation()
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            await store.refresh()
        }
    }

    override func stopAnimation() {
        refreshTask?.cancel()
        refreshTask = nil
        super.stopAnimation()
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)
    }
}
