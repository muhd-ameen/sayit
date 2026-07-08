import SwiftUI
import ServiceManagement

struct SayItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        MenuBarExtra {
            Button("Open SayIt") {
                WindowManager.shared.show()
            }
            .keyboardShortcut("o", modifiers: [.command, .option])

            Divider()

            Button("Contact Support…") {
                AppDelegate.openSupportMail()
            }

            Divider()

            Button("Quit SayIt") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
    }

    /// SwiftPM ships `Assets.xcassets` uncompiled (no `Assets.car`), so
    /// `Image("MenuBarIcon", bundle: .module)` resolves to nothing and the
    /// status item renders invisibly. Load the PNG straight from the resource
    /// bundle instead, with an SF Symbol fallback so the item is never blank.
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
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hasCompletedSetupKey = "hasCompletedSetup"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
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
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.2.0"
        let subject = "SayIt support (v\(version))"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(SettingsView.supportEmail)?subject=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
