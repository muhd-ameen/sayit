import AppKit
import SwiftUI

private final class SayItPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var panel: SayItPanel?
    private var previousApp: NSRunningApplication?

    private init() {}

    func toggle() {
        if let panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            buildPanel()
        }
        // Capture the frontmost app before SayIt takes focus
        previousApp = NSWorkspace.shared.frontmostApplication
        sizeAndPositionUnderNotch()
        NotificationCenter.default.post(name: .sayItWindowDidOpen, object: nil)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    // Hide panel and return focus to the app the user was in before opening SayIt
    func hideAndRefocus() {
        hide()
        let app = previousApp
        previousApp = nil
        app?.activate()
    }

    private func buildPanel() {
        let panel = SayItPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 360),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false

        let content = NSHostingView(rootView: PopupView())
        panel.contentView = content

        self.panel = panel
    }

    private func sizeAndPositionUnderNotch() {
        guard let screen = NSScreen.main, let panel = panel else { return }
        let screenFrame = screen.frame
        let notchHeight = screen.safeAreaInsets.top

        let width = (screenFrame.width / 3).rounded()
        let height = (screenFrame.height / 3).rounded()

        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - notchHeight - height

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}

extension Notification.Name {
    static let sayItWindowDidOpen = Notification.Name("sayItWindowDidOpen")
}
