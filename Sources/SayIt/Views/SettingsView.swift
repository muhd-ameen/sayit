import SwiftUI

struct SettingsView: View {
    @State private var slots = ToneSettings.shared.slots

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
        }
        .padding(16)
        .frame(width: 380)
        .background(Color(red: 0.06, green: 0.06, blue: 0.07))
        .onChange(of: slots) { _, newSlots in
            ToneSettings.shared.slots = newSlots
        }
    }
}
