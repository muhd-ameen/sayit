import SwiftUI

private let bg = Color(red: 0.06, green: 0.06, blue: 0.07)
private let surface = Color(red: 0.10, green: 0.10, blue: 0.12)
private let rimColor = Color.white.opacity(0.08)
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.40)

struct PopupView: View {
    @StateObject private var viewModel = PopupViewModel()
    @State private var showShortcuts = false
    @State private var showSettings = false
    @FocusState private var focus: Field?

    enum Field { case context, draft, nudge }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(rimColor)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    darkField(
                        placeholder: "Conversation / context (optional)…",
                        text: $viewModel.context,
                        field: .context,
                        minHeight: 80
                    )

                    darkField(
                        placeholder: "Your message or rough draft…",
                        text: $viewModel.draft,
                        field: .draft,
                        minHeight: 50
                    )

                    actionRow

                    if !viewModel.replies.isEmpty {
                        Divider().background(rimColor)
                        ForEach(Array(viewModel.replies.enumerated()), id: \.element.id) { index, reply in
                            ResultCardView(reply: reply, shortcut: index + 1) {
                                viewModel.copyReply(at: index)
                            }
                        }
                        nudgeRow
                    }
                }
                .padding(14)
            }
        }
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(rimColor, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { handleWindowOpen() }
        .onReceive(NotificationCenter.default.publisher(for: .sayItWindowDidOpen)) { _ in
            handleWindowOpen()
        }
        // Focus nudge field as soon as first card appears
        .onChange(of: viewModel.replies.isEmpty) { isEmpty in
            if !isEmpty { focus = .nudge }
        }
        .popover(isPresented: $showSettings) {
            SettingsView()
        }
        // Hidden shortcuts
        .background {
            Group {
                Button("") { WindowManager.shared.hide() }
                    .keyboardShortcut("w", modifiers: .command)
                Button("") { showShortcuts.toggle() }
                    .keyboardShortcut("/", modifiers: .command)
            }
            .opacity(0).frame(width: 0, height: 0).accessibilityHidden(true)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 8) {
            // Close button
            Button {
                WindowManager.shared.hide()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(width: 18, height: 18)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close  ⌘W")

            Text("SayIt")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(textPrimary)
            Spacer()
            HStack(spacing: 6) {
                if !viewModel.replies.isEmpty {
                    Button("New") {
                        viewModel.reset()
                        focus = .context
                    }
                    .buttonStyle(GhostButtonStyle())
                    .keyboardShortcut("n", modifiers: .command)
                }

                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(showSettings ? 0.9 : 0.5))
                        .frame(width: 28, height: 24)
                        .background(Color.white.opacity(showSettings ? 0.12 : 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Tone settings")

                Button {
                    showShortcuts.toggle()
                } label: {
                    Image(systemName: "keyboard")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(showShortcuts ? 0.9 : 0.5))
                        .frame(width: 28, height: 24)
                        .background(Color.white.opacity(showShortcuts ? 0.12 : 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Shortcuts  ⌘/")
                .popover(isPresented: $showShortcuts, arrowEdge: .bottom) {
                    ShortcutsPopover()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var actionRow: some View {
        HStack(spacing: 6) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.55)
                    .tint(.white)
                Text("Refining…")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(textSecondary)
            } else if let error = viewModel.errorMessage {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.85))
                Text(error)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.red.opacity(0.85))
                    .lineLimit(1)
            } else {
                Text("⌘ Return")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(textSecondary)
            }

            Spacer()

            Button("Refine") {
                Task { await viewModel.refine() }
            }
            .buttonStyle(AccentButtonStyle())
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(viewModel.isLoading || (viewModel.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
        }
    }

    // MARK: - Helpers

    private func handleWindowOpen() {
        viewModel.prefillFromClipboardIfNeeded()
        if !viewModel.replies.isEmpty {
            focus = .nudge
        } else {
            focus = viewModel.context.isEmpty ? .context : .draft
        }
    }

    private var nudgeRow: some View {
        ZStack(alignment: .leading) {
            if viewModel.nudge.isEmpty {
                Text("Nudge Claude… (↩)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(textSecondary)
                    .allowsHitTesting(false)
            }
            TextField("", text: $viewModel.nudge)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(textPrimary)
                .focused($focus, equals: .nudge)
                .onSubmit {
                    guard !viewModel.nudge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    Task { await viewModel.refine() }
                }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(rimColor, lineWidth: 1)
        )
        .padding(.top, 2)
    }

    @ViewBuilder
    private func darkField(
        placeholder: String,
        text: Binding<String>,
        field: Field,
        minHeight: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(textSecondary)
                    .padding(EdgeInsets(top: 7, leading: 5, bottom: 0, trailing: 0))
                    .allowsHitTesting(false)
            }
            TextEditor(text: text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(textPrimary)
                .hideScrollBackground()
                .focused($focus, equals: field)
        }
        .frame(minHeight: minHeight)
        .padding(6)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(rimColor, lineWidth: 1)
        )
    }
}

// MARK: - Shortcuts popover

private struct ShortcutRow: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(keys)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }
}

struct ShortcutsPopover: View {
    private let rows: [(String, String)] = [
        ("⌥ Space",   "Toggle SayIt"),
        ("⌘ ↩",       "Refine"),
        ("⌘ N",       "New"),
        ("⌘ 1 / 2 / 3", "Copy result"),
        ("⌘ /",       "Show shortcuts"),
        ("⌘ W  /  Esc", "Close"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Shortcuts")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))
                .padding(.bottom, 2)

            ForEach(rows, id: \.0) { keys, label in
                ShortcutRow(keys: keys, label: label)
            }
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .frame(width: 230)
    }
}

// MARK: - Button styles (shared with ResultCardView)

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

// MARK: - Cross-version helpers

extension View {
    /// `scrollContentBackground(.hidden)` is macOS 13+. On macOS 12 the
    /// TextEditor keeps its default backing; the surrounding surface still
    /// reads as dark, so the degradation is cosmetic only.
    @ViewBuilder
    func hideScrollBackground() -> some View {
        if #available(macOS 13, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }

    /// `kerning(_:)` is macOS 13+; a no-op on 12 (letter-spacing is cosmetic).
    @ViewBuilder
    func kerningCompat(_ value: CGFloat) -> some View {
        if #available(macOS 13, *) {
            self.kerning(value)
        } else {
            self
        }
    }

    /// `underline()` is macOS 13+; a no-op on 12 (cosmetic).
    @ViewBuilder
    func underlineCompat() -> some View {
        if #available(macOS 13, *) {
            self.underline()
        } else {
            self
        }
    }
}
