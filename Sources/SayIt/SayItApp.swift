import AppKit
import SwiftUI

// AppKit entry point (no SwiftUI App/MenuBarExtra) so SayIt runs on macOS 12+.
// @MainActor so the delegate can be constructed in a main-actor context.
@main
struct SayItMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hasCompletedSetupKey = "hasCompletedSetup"
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        HotkeyService.shared.setup()

        // One-time cleanup: purge any personal Anthropic key stored by an
        // older version that asked users to bring their own. The app now uses
        // a server-side proxy and never needs a key on-device.
        KeychainService.deleteAPIKey()

        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasCompletedSetupKey)

        if isFirstLaunch {
            runFirstLaunchSetup()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Menu bar

    // AppKit NSStatusItem rather than SwiftUI MenuBarExtra (macOS 13+) so the
    // app runs on macOS 12.
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = Self.menuBarIcon

        let menu = NSMenu()

        let open = NSMenuItem(title: "Open SayIt", action: #selector(openSayIt), keyEquivalent: "o")
        open.keyEquivalentModifierMask = [.command, .option]
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let support = NSMenuItem(title: "Contact Support…", action: #selector(contactSupport), keyEquivalent: "")
        support.target = self
        menu.addItem(support)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit SayIt", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    @objc private func openSayIt() { WindowManager.shared.show() }
    @objc private func contactSupport() { Self.openSupportMail() }
    @objc private func quitApp() { NSApplication.shared.terminate(nil) }

    /// SwiftPM ships `Assets.xcassets` uncompiled (no `Assets.car`), so a
    /// by-name image lookup resolves to nothing and the status item renders
    /// invisibly. Load the PNG straight from the resource bundle instead, with
    /// an SF Symbol fallback so the item is never blank.
    private static let menuBarIcon: NSImage = {
        let imageset = "Assets.xcassets/MenuBarIcon.imageset"
        for name in ["MenuBarIcon@2x", "MenuBarIcon@3x", "MenuBarIcon"] {
            if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: imageset),
               let image = NSImage(contentsOf: url) {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                return image
            }
        }
        let fallback = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "SayIt")
            ?? NSImage(size: NSSize(width: 18, height: 18))
        fallback.isTemplate = true
        return fallback
    }()

    // MARK: - First launch setup

    private func runFirstLaunchSetup() {
        UserDefaults.standard.set(true, forKey: hasCompletedSetupKey)
        showOnboarding()
    }

    private func showOnboarding() {
        let view = OnboardingView(onDone: {
            OnboardingWindowController.close()
        })
        OnboardingWindowController.show(view: view)
    }

    // MARK: - Support

    static func openSupportMail() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.2.2"
        let subject = "SayIt support (v\(version))"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(SettingsView.supportEmail)?subject=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
