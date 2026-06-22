import SwiftUI
import ServiceManagement

struct OnboardingView: View {
    @State private var apiKey = ""
    @State private var launchAtLogin = true
    @State private var showError = false
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)

                Text("Welcome to SayIt")
                    .font(.title2.bold())

                Text("Press ⌥ Space anywhere to refine a message before you send it.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            Divider()

            // API key section
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Anthropic API Key")
                        .font(.headline)
                    Text("Powers Claude. Stored in your Keychain — never leaves this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://console.anthropic.com/settings/keys")!)
                } label: {
                    Label("Get your key at console.anthropic.com", systemImage: "arrow.up.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)

                SecureField("sk-ant-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                if showError {
                    Text("Enter your API key to continue.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Toggle("Launch SayIt at login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
            }
            .padding(32)

            Spacer(minLength: 0)

            // Actions
            VStack(spacing: 8) {
                Button {
                    let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !key.isEmpty else {
                        showError = true
                        return
                    }
                    KeychainService.saveAPIKey(key)
                    if launchAtLogin {
                        try? SMAppService.mainApp.register()
                    }
                    onDone()
                } label: {
                    Text("Save & Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return)

                Button("Skip for now", action: onDone)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(width: 400, height: 460)
    }
}
