# Quick Capture

Press **⌘⇧Space** anywhere → type → **⌘↵** → file lands in `~/Documents/cxkb/raw/inbox/`. Native macOS, designed for sub-50ms hotkey-to-typing.

## Build & install

```bash
./build-app.sh
./build-app.sh install
open /Applications/QuickCapture.app
```

First run asks for **Accessibility** permission (needed for the global hotkey and the focused-window-title read). Grant it in System Settings, then quit and relaunch.

The first time you capture from each supported browser (Safari, Chrome, Arc, Brave, Edge), macOS prompts for AppleEvents permission so the tab URL can be pulled.

## What lands in the inbox

```yaml
---
captured: 2026-05-22T03:24:16Z
hotkey: cmd-shift-space
app: "Safari"
window: "Some article title"
url: "https://example.com/article"
---

<the body you typed>
```

## Menu bar

Click the pencil icon → `Capture…`, `Launch at Login` (toggle), `Quit Quick Capture`.
