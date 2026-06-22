import Foundation

enum PromptBuilder {
    static let systemPrompt = """
    You refine messages for a busy person who values clarity and speed.

    Voice: direct, short sentences, human, action-oriented. Slack/Discord/WhatsApp register.
    Never: corporate speak, LinkedIn fluff, overexplaining, sycophantic openers/closers, em dashes (—).
    Use a comma or period instead of an em dash. No exceptions.
    Intent beats grammar. If already good, change as little as possible.
    """

    static func build(
        context: String,
        draft: String,
        tones: [ToneSlot],
        nudge: String? = nil,
        previousDefault: String? = nil
    ) -> String {
        let ctx = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let dft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let ndg = nudge?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var body: String
        if ctx.isEmpty {
            // Composing from scratch — no conversation context
            body = "Draft:\n\(dft)\n\nPolish this. Fix grammar, preserve intent, stay tight."
        } else if dft.isEmpty {
            // Replying without a draft
            body = "Conversation:\n\(ctx)\n\nWrite a reply in Ameen's voice."
        } else {
            // Replying with a draft
            body = "Conversation:\n\(ctx)\n\nDraft:\n\(dft)\n\nRefine the draft. Fix grammar, preserve intent, stay tight."
        }

        if !ndg.isEmpty {
            if let prev = previousDefault, !prev.isEmpty {
                body += "\n\nPrevious result: \"\(prev)\"\nNudge: \(ndg)"
            } else {
                body += "\n\nAdditional instruction: \(ndg)"
            }
        }

        let toneLines = tones.map { "  \"\($0.id)\": \($0.instruction)" }.joined(separator: "\n")
        let jsonTemplate = "{" + tones.map { "\"\($0.id)\":\"...\"" }.joined(separator: ",") + "}"

        return """
        \(body)

        Produce \(tones.count) variants:
        \(toneLines)

        Reply with ONLY valid JSON, no prose, no markdown:
        \(jsonTemplate)
        """
    }
}
