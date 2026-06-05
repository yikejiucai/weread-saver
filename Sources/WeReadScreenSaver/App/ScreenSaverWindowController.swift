import AppKit
import SwiftUI

@MainActor
final class ScreenSaverWindowController: NSObject {
    private let window: NSWindow

    init(rootView: some View) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .black
        window.level = .screenSaver
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.contentView = NSHostingView(rootView: rootView)

        super.init()

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func showFullScreen() {
        window.setFrame(window.screen?.frame ?? window.frame, display: true)
        window.orderFrontRegardless()
    }
}
