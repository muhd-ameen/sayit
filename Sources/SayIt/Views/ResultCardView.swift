import SwiftUI

private let cardBg = Color(red: 0.10, green: 0.10, blue: 0.12)
private let cardBorder = Color.white.opacity(0.08)
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.40)

struct ResultCardView: View {
    let reply: RefinedReply
    let shortcut: Int
    let onCopy: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(reply.label.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(textSecondary)
                    .kerning(0.6)

                Spacer()

                Button {
                    onCopy()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(copied ? "Copied" : "Copy  ⌘\(shortcut)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .animation(.easeInOut(duration: 0.15), value: copied)
                }
                .buttonStyle(GhostButtonStyle())
                .keyboardShortcut(KeyEquivalent(Character("\(shortcut)")), modifiers: .command)
            }

            Text(reply.text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}
