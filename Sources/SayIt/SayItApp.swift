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

            Button("Set API Key…") {
                AppDelegate.promptForAPIKey()
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

        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasCompletedSetupKey)

        if isFirstLaunch {
            runFirstLaunchSetup()
        } else if KeychainService.loadAPIKey() == nil &&
                  (ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "").isEmpty {
            AppDelegate.promptForAPIKey()
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

    // MARK: - API Key prompt

    static func promptForAPIKey() {
        let alert = NSAlert()
        alert.messageText = "Anthropic API Key"
        alert.informativeText = "Enter your API key from console.anthropic.com. Stored securely in your Keychain."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 380, height: 24))
        field.placeholderString = "sk-ant-..."
        if let existing = KeychainService.loadAPIKey() {
            field.stringValue = existing
        }
        alert.accessoryView = field

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty {
                KeychainService.saveAPIKey(key)
            }
        }
    }
}
