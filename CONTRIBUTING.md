# Contributing to SayIt

Thanks for taking the time. SayIt is a small, opinionated utility — contributions that keep it fast, focused, and friction-free are most welcome.

## What's welcome

- Bug fixes
- Performance improvements
- New built-in tone presets
- Accessibility improvements
- Fixes to the `make` build pipeline

## What's out of scope

- Adding a backend or user accounts
- Bundling other AI providers (Claude-only by design)
- Features that add UI surface area without clear daily-use value

If you're unsure, [open an issue](https://github.com/muhd-ameen/sayit/issues/new) first and describe what you want to change.

## Getting started

```bash
git clone https://github.com/muhd-ameen/sayit
cd sayit
swift build
```

Run in development:

```bash
ANTHROPIC_API_KEY=sk-ant-... swift run
```

## Making changes

1. Fork the repo and create a branch (`git checkout -b fix/your-change`)
2. Make your change — keep it small and focused
3. Build and test locally (`swift build -c release`)
4. Open a pull request with a clear description of what and why

## Code style

- Swift standard formatting — no third-party formatters required
- No comments unless the why is genuinely non-obvious
- Keep new files in the existing `Services / Views / Models / Utilities` structure

## Reporting bugs

[Open an issue](https://github.com/muhd-ameen/sayit/issues/new) with:
- macOS version
- What you did
- What you expected
- What happened instead
