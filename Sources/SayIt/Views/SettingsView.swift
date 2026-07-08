import SwiftUI

struct SettingsView: View {
    @State private var slots = ToneSettings.shared.slots

    static let supportEmail = "ameen@appetite.studio"

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.2.0"
        let build = info?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? "v\(short)" : "v\(short) (\(build))"
    }

    private func openSupportMail() {
        let subject = "SayIt support (\(versionString))"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:\(Self.supportEmail)?subject=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tone Slots")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text("Label · Voice instruction sent to Claude")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))

            ForEach($slots) { $slot in
                HStack(spacing: 8) {
                    TextField("Label", text: $slot.label)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 96)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    TextField("Voice instruction for Claude", text: $slot.instruction)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            Button("Reset to defaults") {
                slots = ToneSlot.defaults
            }
            .buttonStyle(GhostButtonStyle())
            .padding(.top, 2)

            HStack {
                Text("SayIt")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))

                Button(action: openSupportMail) {
                    Text("Contact support")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .underline()
                }
                .buttonStyle(.plain)
                .help("Something went wrong? Email \(Self.supportEmail)")

                Spacer()
                Text(versionString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .padding(.top, 6)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .frame(width: 380)
        .background(Color(red: 0.06, green: 0.06, blue: 0.07))
        .onChange(of: slots) { _, newSlots in
            ToneSettings.shared.slots = newSlots
        }
    }
}
