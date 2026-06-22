import AppKit
import SwiftUI

enum OnboardingWindowController {
    private static var window: NSWindow?

    static func show(view: some View) {
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.styleMask = [.titled, .closable]
        win.titlebarAppearsTransparent = true
        win.title = ""
        win.isReleasedWhenClosed = false
        win.center()
        window = win
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
    }

    static func close() {
        window?.close()
        window = nil
    }
}
