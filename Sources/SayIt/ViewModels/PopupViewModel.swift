import SwiftUI
import Observation

@Observable
@MainActor
final class PopupViewModel {
    var context: String = ""
    var draft: String = ""
    var nudge: String = ""
    var replies: [RefinedReply] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func refine() async {
        let hasContent = !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasContent else { return }

        // Capture nudge context before clearing
        let previousDefault = nudge.isEmpty ? nil : replies.first?.text
        let currentNudge = nudge.isEmpty ? nil : nudge

        isLoading = true
        errorMessage = nil
        replies = []
        nudge = ""

        let tones = ToneSettings.shared.slots
        let stream = await ClaudeService.shared.refineStream(
            context: context,
            draft: draft,
            nudge: currentNudge,
            tones: tones,
            previousDefault: previousDefault
        )

        do {
            for try await partialReplies in stream {
                replies = partialReplies
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func reset() {
        context = ""
        draft = ""
        nudge = ""
        replies = []
        errorMessage = nil
        isLoading = false
    }

    func copyReply(at index: Int) {
        guard index < replies.count else { return }
        ClipboardService.copy(replies[index].text)
        WindowManager.shared.hideAndRefocus()
        // Reset after the panel hides so the next open starts fresh
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            reset()
        }
    }

    func prefillFromClipboardIfNeeded() {
        let clipboard = ClipboardService.get()
        guard clipboard.count > 20, context.isEmpty else { return }
        context = clipboard
    }
}
