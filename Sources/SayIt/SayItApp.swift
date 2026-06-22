import SwiftUI
import ServiceManagement

struct SayItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        MenuBarExtra("SayIt", systemImage: "bubble.left.and.text.bubble.right") {
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
        AppDelegate.promptForAPIKey()
        promptForLoginItem()
        UserDefaults.standard.set(true, forKey: hasCompletedSetupKey)
    }

    private func promptForLoginItem() {
        guard SMAppService.mainApp.status != .enabled else { return }

        let alert = NSAlert()
        alert.messageText = "Launch SayIt at Login?"
        alert.informativeText = "SayIt will start automatically when you log in, so ⌥ Space is always ready."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes, Launch at Login")
        alert.addButton(withTitle: "Not Now")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            do {
                try SMAppService.mainApp.register()
            } catch {
                // If registration fails (e.g. app not in /Applications yet), silently skip.
                // User can enable it later via menu bar → Set API Key flow or System Settings.
            }
        }
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
