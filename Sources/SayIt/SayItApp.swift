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
            Image("MenuBarIcon", bundle: .module)
                .renderingMode(.template)
        }
    }
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
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        let subject = "SayIt support (v\(version))"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(SettingsView.supportEmail)?subject=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
