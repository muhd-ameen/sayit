import Foundation

enum ClaudeError: LocalizedError, Sendable {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not found. Set ANTHROPIC_API_KEY or use the menu bar to add one."
        case .networkError(let e):
            return "Network error: \(e.localizedDescription)"
        case .invalidResponse:
            return "Unexpected response from Claude. Try again."
        case .apiError(let status, let msg):
            return "Claude API error \(status): \(msg)"
        }
    }
}

private struct SSEEvent: Decodable {
    let type: String
    let delta: SSEDelta?

    struct SSEDelta: Decodable {
        let type: String?
        let text: String?
    }
}

actor ClaudeService {
    static let shared = ClaudeService()

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5"

    private var apiKey: String? {
        if let key = KeychainService.loadAPIKey() { return key }
        let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        return env.isEmpty ? nil : env
    }

    func refineStream(
        context: String,
        draft: String,
        nudge: String?,
        tones: [ToneSlot],
        previousDefault: String?
    ) -> AsyncThrowingStream<[RefinedReply], Error> {
        // Capture everything needed before leaving actor isolation
        let capturedKey = apiKey
        let capturedURL = apiURL
        let capturedModel = model
        let prompt = PromptBuilder.build(
            context: context, draft: draft, tones: tones,
            nudge: nudge, previousDefault: previousDefault
        )
        let system = PromptBuilder.systemPrompt

        return AsyncThrowingStream { continuation in
            Task { [self] in
                guard let key = capturedKey else {
                    continuation.finish(throwing: ClaudeError.missingAPIKey)
                    return
                }

                var request = URLRequest(url: capturedURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(key, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                let body: [String: Any] = [
                    "model": capturedModel,
                    "max_tokens": 512,
                    "stream": true,
                    "system": system,
                    "messages": [["role": "user", "content": prompt]]
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                } catch {
                    continuation.finish(throwing: ClaudeError.networkError(error))
                    return
                }

                let bytes: URLSession.AsyncBytes
                let response: URLResponse
                do {
                    (bytes, response) = try await URLSession.shared.bytes(for: request)
                } catch {
                    continuation.finish(throwing: ClaudeError.networkError(error))
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    continuation.finish(throwing: ClaudeError.invalidResponse)
                    return
                }

                guard http.statusCode == 200 else {
                    var errData = Data()
                    do { for try await byte in bytes { errData.append(byte) } } catch {}
                    let msg = String(data: errData, encoding: .utf8) ?? "Unknown error"
                    continuation.finish(throwing: ClaudeError.apiError(http.statusCode, msg))
                    return
                }

                var accumulated = ""
                var lastYieldedCount = 0

                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        guard payload != "[DONE]" else { break }

                        guard
                            let data = payload.data(using: .utf8),
                            let event = try? JSONDecoder().decode(SSEEvent.self, from: data),
                            event.type == "content_block_delta",
                            let text = event.delta?.text
                        else { continue }

                        accumulated += text

                        // Yield incrementally when a new complete card is available
                        if let partial = self.extractCompletedReplies(from: accumulated, tones: tones),
                           partial.count > lastYieldedCount {
                            lastYieldedCount = partial.count
                            continuation.yield(partial)
                        }
                    }
                } catch {
                    continuation.finish(throwing: ClaudeError.networkError(error))
                    return
                }

                // Final authoritative parse (handles any trailing content)
                if let final = try? self.parseReplies(from: accumulated, tones: tones) {
                    continuation.yield(final)
                }

                continuation.finish()
            }
        }
    }

    // MARK: - Parsing (nonisolated — pure computation, no actor state)

    nonisolated private func parseReplies(from text: String, tones: [ToneSlot]) throws -> [RefinedReply] {
        let jsonString = extractJSON(from: text)
        guard
            let jsonData = jsonString.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String]
        else {
            throw ClaudeError.invalidResponse
        }

        let replies = tones.compactMap { tone -> RefinedReply? in
            guard let value = parsed[tone.id], !value.isEmpty else { return nil }
            return RefinedReply(label: tone.label, text: value)
        }

        guard !replies.isEmpty else { throw ClaudeError.invalidResponse }
        return replies
    }

    // Extracts cards whose values are confirmed complete (followed by , or })
    nonisolated private func extractCompletedReplies(from text: String, tones: [ToneSlot]) -> [RefinedReply]? {
        var replies: [RefinedReply] = []
        for tone in tones {
            guard let value = extractCompletedValue(for: tone.id, from: text) else { break }
            replies.append(RefinedReply(label: tone.label, text: unescape(value)))
        }
        return replies.isEmpty ? nil : replies
    }

    // Returns a field's value only when its closing quote is followed by , or } (never truncated)
    nonisolated private func extractCompletedValue(for key: String, from text: String) -> String? {
        let marker = "\"\(key)\":"
        guard let markerRange = text.range(of: marker) else { return nil }

        let afterKey = text[markerRange.upperBound...]
        guard afterKey.first == "\"" else { return nil }

        let valueStart = afterKey.index(after: afterKey.startIndex)
        var pos = valueStart
        var escaped = false

        while pos < afterKey.endIndex {
            let c = afterKey[pos]
            if escaped {
                escaped = false
            } else if c == "\\" {
                escaped = true
            } else if c == "\"" {
                let nextPos = afterKey.index(after: pos)
                if nextPos < afterKey.endIndex {
                    let next = afterKey[nextPos]
                    if next == "," || next == "}" {
                        return String(afterKey[valueStart..<pos])
                    }
                }
                return nil // closing quote not confirmed — truncated
            }
            pos = afterKey.index(after: pos)
        }
        return nil
    }

    nonisolated private func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\\"", with: "\"")
         .replacingOccurrences(of: "\\n", with: "\n")
         .replacingOccurrences(of: "\\\\", with: "\\")
    }

    nonisolated private func extractJSON(from text: String) -> String {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}")
        else { return text }
        return String(text[start...end])
    }
}
