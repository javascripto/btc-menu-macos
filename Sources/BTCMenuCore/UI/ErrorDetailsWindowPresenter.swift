import AppKit
import SwiftUI

@MainActor
final class ErrorDetailsWindowPresenter {
    private var window: NSWindow?

    func show(details: ErrorDetails) {
        let controller = NSHostingController(rootView: ErrorDetailsWindowView(details: details))

        if let window {
            window.contentViewController = controller
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Último erro"
        window.contentViewController = controller
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
