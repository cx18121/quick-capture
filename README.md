# Quick Capture

Native macOS app: global hotkey → tiny floating panel → type → ⌘↵ → file lands in `~/Documents/cxkb/raw/inbox/`. The missing low-friction *capture* end of the [cxkb](~/Documents/cxkb/) pipeline.

> **Status: v0.2 — working.** Tested on macOS 13+. Currently personal-use; no distribution intent.

## The loop

1. Press **⌘⇧Space** anywhere (configurable later, hard-coded for now).
2. A dark 640×200 panel appears centered, slightly above middle. Cursor blinks inside.
3. Type. Multi-line works. First non-empty line becomes the filename slug.
4. **⌘↵** saves. The panel border briefly pulses green, then dismisses.
5. The file lands at `~/Documents/cxkb/raw/inbox/YYYY-MM-DD-HHMM-<slug>.md`.

**⎋** dismisses without saving. **⌘⇧Space** while the panel is open also dismisses.

## What gets written

```yaml
---
captured: 2026-05-22T03:24:16Z
hotkey: cmd-shift-space
app: "Safari"
window: "Some article title"
url: "https://example.com/article"
---

<your captured text>
```

- `app` and `window` come from `NSWorkspace.frontmostApplication` and AX (`kAXFocusedWindowAttribute` → `kAXTitleAttribute`), captured *before* Quick Capture activates itself.
- `url` is pulled via AppleScript for Safari, Chrome, Arc, Brave, and Edge. Other browsers / non-browsers omit the field.
- When Quick Capture is itself frontmost (e.g. invoked via the menu bar item), the tracker falls back to whatever app was previously active.

## Setup

```bash
./build-app.sh           # builds .build/QuickCapture.app
./build-app.sh install   # installs to /Applications/QuickCapture.app
open /Applications/QuickCapture.app
```

**First run:** macOS will ask for **Accessibility** permission — Quick Capture needs it both for the global hotkey (`CGEventTap`) and for reading the focused window title. Grant it in System Settings → Privacy & Security → Accessibility, then **quit and relaunch** (TCC doesn't reload grants live).

**Per browser:** the first time Quick Capture pulls a URL from each browser, macOS prompts for AppleEvents permission. Click Allow once per browser.

### Signing

`build-app.sh` signs with the developer identity `Apple Development: charlie.l.xue@gmail.com (2L525PQAPB)` if present in the keychain; falls back to ad-hoc otherwise. The Apple Dev signature keeps the TCC grant stable across rebuilds — without it, every rebuild changes the cdhash and requires re-granting Accessibility.

If you ever need to start fresh:

```bash
./build-app.sh install --reset-tcc
```

This wipes the Accessibility entry for the bundle ID. Re-grant in System Settings.

## Menu bar

The status item (✏️ pencil glyph) holds:

- **Capture…** — same as pressing the hotkey.
- **Launch at Login** — toggle. Backed by `SMAppService.mainApp`; checkmark reflects current state. Strongly recommended on, otherwise the hotkey is dead whenever you forget to launch.
- **Quit Quick Capture**.

## Project layout

```
quick-capture/
├── Package.swift
├── build-app.sh
└── Sources/QuickCapture/
    ├── main.swift                       NSApplication bootstrap (.accessory)
    ├── AppDelegate.swift                wires permissions, tracker, hotkey, panel, status item
    ├── System/
    │   ├── HotkeyManager.swift          CGEventTap for ⌘⇧Space, autorepeat-filtered
    │   ├── PermissionsManager.swift     Accessibility prompt + jump-to-settings
    │   ├── FrontmostAppTracker.swift    NSWorkspace observer for non-self last-active app
    │   ├── CaptureContext.swift         struct + AX + AppleScript URL reader
    │   ├── InboxWriter.swift            slug, frontmatter (YAML-quoted), atomic write
    │   └── LaunchAtLoginManager.swift   SMAppService.mainApp wrapper
    ├── Menu/
    │   └── StatusItemController.swift   NSStatusItem + menu + delegate
    └── Overlay/
        ├── CapturePanel.swift           NSPanel — .nonactivatingPanel, .screenSaver level
        ├── CaptureController.swift      panel lifecycle, context snapshot
        └── CaptureView.swift            SwiftUI TextEditor + ⌘↵ shortcut + green save flash
```

## Heritage

Scaffolded from the [`screen-pilot`](https://github.com/cx18121/screen-pilot) sibling repo. The hotkey manager, overlay panel, and build-app.sh approach are adapted from there. Screen Pilot is being retired in favor of Quick Capture (Charlie wasn't using it — the per-prompt API cost made him pivot to the dump-to-inbox pattern that this app is built for).

## Known limits / deferred to v0.3+

- **Configurable hotkey** — currently hard-coded ⌘⇧Space.
- **Configurable target directory** — currently hard-coded `~/Documents/cxkb/raw/inbox/`.
- **Voice capture** — hold-hotkey-to-record via Speech framework.
- **Firefox URL** — Firefox doesn't expose URL via AppleScript.
- **Auto-commit** — git commit the new file inside the cxkb repo automatically.
- **Edit auto-context** — let the user override app/window/url if the auto-detection is wrong.
- **Persistent draft on accidental ⎋** — currently a hit on ⎋ loses the buffer.

## When this is "done enough"

v0.1 shipped when reaching for ⌘⇧Space replaced reaching for Notes.app. v0.2 closed the trust loop (visible save confirmation, launch-at-login, URL context). Future versions should be driven by friction encountered in real use — not by speculation.
