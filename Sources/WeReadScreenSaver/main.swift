import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: ScreenSaverWindowController?
    private var eventMonitors: [Any] = []
    private let store = ShelfStore(
        provider: ChromeBrowserShelfProvider(
            fallback: SampleShelfProvider.sample()
        )
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSCursor.hide()

        let rootView = RootView(
            store: store,
            onExitRequested: { [weak self] in
                self?.terminate()
            }
        )

        let controller = ScreenSaverWindowController(rootView: rootView)
        controller.showFullScreen()
        windowController = controller
        installExitMonitors()

        Task {
            await store.refresh()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventMonitors.forEach(NSEvent.removeMonitor)
        eventMonitors.removeAll()
        NSCursor.unhide()
    }

    private func terminate() {
        NSCursor.unhide()
        NSApp.terminate(nil)
    }

    private func installExitMonitors() {
        let monitorMask: NSEvent.EventTypeMask = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel,
            .magnify,
            .swipe,
            .rotate
        ]

        let monitor = NSEvent.addLocalMonitorForEvents(matching: monitorMask) { [weak self] event in
            switch event.type {
            case .scrollWheel, .magnify, .swipe, .rotate:
                self?.terminate()
                return nil
            case .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown:
                self?.terminate()
                return nil
            default:
                return event
            }
        }

        if let monitor {
            eventMonitors.append(monitor)
        }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
