import AppKit
import SwiftUI

@MainActor
final class StatusItemPopoverPresenter {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        popover.behavior = .transient
        popover.animates = true
    }

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        guard let button = statusItem.button else { return }

        let hostingController = NSHostingController(rootView: content())
        hostingController.view.frame.size = hostingController.view.fittingSize
        popover.contentViewController = hostingController

        if popover.isShown {
            popover.performClose(nil)
        }

        DispatchQueue.main.async { [weak self, weak button] in
            guard let self, let button else { return }
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.window?.makeKey()
        }
    }

    func close() {
        popover.performClose(nil)
    }
}
