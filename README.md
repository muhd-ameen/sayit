<p align="center">
  <img src="assets/logo.png" width="120" alt="SayIt" />
</p>

# SayIt

A tiny macOS menu bar utility that refines messages before you send them, without switching to ChatGPT or disrupting your flow.

Press **⌥ Space** anywhere. Type your draft. Get three polished variants instantly. Copy. Done.

---

## Features

- **Global hotkey.** ⌥ Space opens the panel from any app
- **Three tone slots.** Default, Shorter, Professional (fully customizable)
- **Nudge.** Iterate on a result with a one-line instruction
- **Context field.** Paste a conversation thread so Claude can write the perfect reply
- **Clipboard prefill.** Opens with your clipboard text already loaded
- **Streaming.** Results appear card-by-card as Claude generates them
- **API key in Keychain.** Stored securely, never in plaintext
- **No backend, no account.** Direct Anthropic API call from your Mac

---

## Requirements

- macOS 14 (Sonnet) or later
- [Anthropic API key](https://console.anthropic.com)
- Xcode 15+ or Swift 5.9+ CLI tools

---

## Install

### Build from source

```bash
git clone https://github.com/muhd-ameen/sayit
cd sayit
swift build -c release
```

The binary lands at `.build/release/SayIt`. Copy it to `/Applications` for launch-at-login support.

### Run directly

```bash
swift run
```

---

## Setup

On first launch SayIt will ask for your Anthropic API key. It's stored in your macOS Keychain under `SayIt`.

You can also set it via environment variable (useful for development):

```bash
ANTHROPIC_API_KEY=sk-ant-... swift run
```

To update the key later: menu bar icon > **Set API Key…**

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌥ Space | Toggle SayIt |
| ⌘ ↩ | Refine |
| ⌘ N | New / reset |
| ⌘ 1 / 2 / 3 | Copy result |
| ⌘ / | Show shortcuts |
| ⌘ W / Esc | Close |

---

## Customizing tones

Click the gear icon to edit your three tone slots. Each slot has a **label** (shown on the card) and an **instruction** (sent verbatim to Claude).

Defaults:

| Label | Instruction |
|---|---|
| Default | natural, direct voice |
| Shorter | same message, as few words as possible |
| Professional | formal register, polished |

Change them to anything: "Friendly", "Brutal honesty", "Gen Z", whatever fits your workflow.

---

## How it works

```
⌥ Space
  └─ WindowManager shows floating NSPanel
       └─ PopupView reads context + draft
            └─ ClaudeService streams claude-haiku-4-5
                 └─ JSON response: { "default": "…", "shorter": "…", "professional": "…" }
                      └─ Result cards appear as each field completes
```

No server. No telemetry. One API call per refine.

---

## Project structure

```
Sources/SayIt/
├── SayItApp.swift          # App entry, menu bar, first-launch setup
├── main.swift
├── Models/
│   ├── RefinedReply.swift  # Result value type
│   └── ToneSlot.swift      # Tone config + UserDefaults persistence
├── Services/
│   ├── ClaudeService.swift # Streaming Anthropic API actor
│   ├── ClipboardService.swift
│   ├── HotkeyService.swift # ⌥ Space via KeyboardShortcuts
│   ├── KeychainService.swift
│   └── PromptBuilder.swift # System prompt + user prompt construction
├── Utilities/
│   └── WindowManager.swift # NSPanel lifecycle
└── Views/
    ├── PopupView.swift      # Main panel UI
    ├── ResultCardView.swift # Individual tone card
    └── SettingsView.swift   # Tone slot editor
```

---

## Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts): global hotkey registration

---

## Customizing the system prompt

Open `Sources/SayIt/Services/PromptBuilder.swift` and edit `systemPrompt` to match your own voice. The default is intentionally generic.

---

## License

MIT. See [LICENSE](LICENSE).
