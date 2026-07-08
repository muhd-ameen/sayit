<p align="center">
  <img src="assets/logo.png" width="120" alt="SayIt" />
</p>

# SayIt

**[sayit.avocadonation.xyz](https://sayit.avocadonation.xyz)**

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
- **Zero setup.** No Anthropic API key, no account — download and start refining
- **Private.** Your draft is sent over HTTPS to SayIt's proxy and straight to Claude; messages aren't stored

---

## Requirements

**To use it:** macOS 14 (Sonoma) or later, on Apple Silicon or Intel. That's it — no API key, no account.

**To build from source:** Xcode 15+ or Swift 5.9+ CLI tools, plus a `SAYIT_APP_TOKEN` — the shared token the app sends to the refine proxy. Without it, the build runs but refining returns 401.

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

None. SayIt works the moment you open it — refining runs through SayIt's hosted proxy, so there's no API key to enter and no account to create.

Building from source? Pass the proxy token at build/run time:

```bash
SAYIT_APP_TOKEN=... swift run     # development
SAYIT_APP_TOKEN=... make app      # signed .app bundle
```

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
            └─ ClaudeService → POST { system, prompt } to the SayIt proxy
                 └─ Proxy adds the Anthropic key, streams claude-haiku-4-5
                      └─ JSON response: { "default": "…", "shorter": "…", "professional": "…" }
                           └─ Result cards appear as each field completes
```

The proxy is a small [Netlify function](site/netlify/functions/refine.mts) that holds the Anthropic key server-side, so it never ships in the app. It pins the model and token limits, rate-limits per IP, and streams Claude's response straight back. No telemetry; messages aren't stored.

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
│   ├── AppConfig.swift     # Proxy URL + app token (token injected at build time)
│   ├── ClaudeService.swift # Streams refinements through the proxy
│   ├── ClipboardService.swift
│   ├── HotkeyService.swift # ⌥ Space via KeyboardShortcuts
│   ├── KeychainService.swift # Clears any legacy on-device API key
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

---

## Known issues

- **Login item may fail outside `/Applications`** — "Launch at login" can silently fail if the app isn't in `/Applications` or was installed without `make install`. Workaround: add manually via System Settings → General → Login Items.
- **Menu bar icon missing after manual copy** — If you copy `SayIt.app` manually instead of using `make install`, the icon may not appear until you run `xattr -cr /Applications/SayIt.app` and relaunch.

See [open issues](https://github.com/muhd-ameen/sayit/issues) or [open a new one](https://github.com/muhd-ameen/sayit/issues/new) if you hit something not listed here.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
