import SwiftUI
import ServiceManagement

struct OnboardingView: View {
    @State private var launchAtLogin = true
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

            // Preferences
            VStack(alignment: .leading, spacing: 14) {
                Text("No setup needed — SayIt works right away.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Toggle("Launch SayIt at login", isOn: $launchAtLogin)
                    .toggleStyle(.checkbox)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)

            Spacer(minLength: 0)

            // Actions
            Button {
                if launchAtLogin {
                    // SMAppService is macOS 13+. On macOS 12 launch-at-login is
                    // skipped; users can add SayIt under Login Items manually.
                    if #available(macOS 13, *) {
                        try? SMAppService.mainApp.register()
                    }
                }
                onDone()
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return)
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(width: 400, height: 360)
    }
}
