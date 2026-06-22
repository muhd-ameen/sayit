import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Default: ⌥ + Space
    static let toggleSayIt = Self("toggleSayIt", default: .init(.space, modifiers: .option))
}

@MainActor
final class HotkeyService {
    static let shared = HotkeyService()

    private init() {}

    func setup() {
        KeyboardShortcuts.onKeyUp(for: .toggleSayIt) {
            Task { @MainActor in
                WindowManager.shared.toggle()
            }
        }
    }
}
