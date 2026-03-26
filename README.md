# ClipBoard

[![Download v1.1](https://img.shields.io/badge/Download-v1.1-brightgreen?style=for-the-badge&logo=apple&logoColor=white)](https://mega.nz/file/575V0JwZ#cbAz5LzmlXbH-uBxgZym_cMcKce8K-MRhcLqfbiOYH0)

> A lightweight macOS menu bar app that keeps your clipboard and screenshot history always within reach.

```
┌─────────────────────────────────────────┐
│  📋 ClipBoard                 Clear All │
├─────────────────────────────────────────┤
│  🗒  Hello from ChatGPT          ×      │
│  🗒  git commit -m "fix bug"     ×      │
│  🗒  https://example.com         ×      │
│  📸  Screenshot 2026-03-26.png   ×      │
│  🗒  npm install                 ×      │
├─────────────────────────────────────────┤
│  ☑ Launch at login   Limit: 20 ▲▼      │
│                                         │
│  ⏻  Quit ClipBoard                      │
└─────────────────────────────────────────┘
```

---

## What is ClipBoard?

ClipBoard lives in your **menu bar** — no Dock icon, no windows, no clutter. Every time you copy text, code, a URL, or take a screenshot, it silently captures the item and keeps it ready. Click the menu bar icon to browse history, click any item to copy it back instantly.

---

## Features

| | Feature | Details |
|---|---|---|
| 📋 | **Clipboard history** | Captures everything you copy with `Cmd+C` |
| 🌐 | **Web app support** | Picks up "Copy" buttons in ChatGPT, GitHub, Notion, etc. via HTML/RTF fallback |
| 📸 | **Screenshot tracking** | Auto-detects new screenshots saved to `~/Desktop` |
| 🖼 | **Direct screenshot copy** | Also captures `Ctrl+Cmd+Shift+4` (copy-to-clipboard screenshots) |
| 🔁 | **One-click re-copy** | Tap any item in the list to put it back on your clipboard |
| 🗑 | **Per-item delete** | Hover any item and hit `×` to remove it |
| 🧹 | **Clear all** | Wipe the full history in one click |
| 🔢 | **Configurable limit** | Keep 5–100 items (default: 20), oldest auto-removed |
| 🚀 | **Launch at login** | Optional toggle — starts silently with macOS |
| ⏻  | **Quit from menu** | No need for Activity Monitor or force-quit |

---

## How It Works

```
┌──────────────────────────────────────────────────────────┐
│                      ClipBoard App                       │
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────────┐ │
│  │  ClipboardManager   │   │    ScreenshotWatcher      │ │
│  │                     │   │                           │ │
│  │  Polls NSPasteboard │   │  Polls ~/Desktop every 2s │ │
│  │  every 0.5 seconds  │   │  for new Screenshot*.png  │ │
│  │                     │   │                           │ │
│  │  Plain text         │   │  Emits ClipboardItem      │ │
│  │  → HTML fallback    │   │  (type: "image")          │ │
│  │  → RTF fallback     │   │                           │ │
│  └──────────┬──────────┘   └──────────────┬────────────┘ │
│             │  ClipboardItem               │              │
│             └──────────────┬──────────────┘              │
│                            ▼                             │
│                 ┌─────────────────────┐                  │
│                 │   HistoryManager    │                  │
│                 │                     │                  │
│                 │  @Published items[] │                  │
│                 │  Dedup + FIFO trim  │                  │
│                 │  Persists to        │                  │
│                 │  UserDefaults       │                  │
│                 └──────────┬──────────┘                  │
│                            │                             │
│                            ▼                             │
│                 ┌─────────────────────┐                  │
│                 │    MenuBarView      │                  │
│                 │  (SwiftUI dropdown) │                  │
│                 └─────────────────────┘                  │
└──────────────────────────────────────────────────────────┘
```

---

## Architecture

The app is split into focused, single-responsibility modules:

```
ClipBoard/
├── ClipBoardApp.swift        # @main entry point, AppDelegate, AppCoordinator
├── ClipboardManager.swift    # NSPasteboard polling + ClipboardItem model
├── ScreenshotWatcher.swift   # ~/Desktop polling for new screenshots
├── HistoryManager.swift      # History state, persistence (UserDefaults)
├── SettingsManager.swift     # User preferences (limit, launch at login)
├── MenuBarView.swift         # SwiftUI menu bar UI
├── DebugLogger.swift         # dlog() — debug-only print wrapper
├── Info.plist                # LSUIElement, bundle metadata
└── ClipBoard.entitlements    # App Sandbox, Desktop folder access
```

**Data flow:** `ClipboardManager` and `ScreenshotWatcher` each publish a `PassthroughSubject<ClipboardItem, Never>`. `HistoryManager` subscribes to both, deduplicates, trims to the configured limit, and persists to `UserDefaults`. `MenuBarView` observes `HistoryManager` via `@ObservedObject`.

---

## Clipboard Detection

ClipBoard uses a three-tier fallback to capture copies from any source:

```
NSPasteboard changed?
        │
        ├─ 1. Plain text (.string)      ← Cmd+C in any app
        │
        ├─ 2. HTML (.html) → strip tags ← "Copy" buttons in web apps
        │                                  (ChatGPT, GitHub, Notion…)
        │
        ├─ 3. RTF (.rtf) → plain text   ← Rich text from native apps
        │
        └─ 4. TIFF/PNG image            ← Ctrl+Cmd+Shift+4
```

---

## Requirements

| | |
|---|---|
| **macOS** | 13.0 Ventura or later |
| **Architecture** | Apple Silicon & Intel (Universal) |
| **Swift** | 5.9+ |
| **Xcode** | 15+ |

---

## Installation

### Option 1 — Download (Recommended)

[![Download v1.1](https://img.shields.io/badge/Download-v1.1-brightgreen?style=for-the-badge&logo=apple&logoColor=white)](https://mega.nz/file/575V0JwZ#cbAz5LzmlXbH-uBxgZym_cMcKce8K-MRhcLqfbiOYH0)

1. Click the **Download** badge above and save `ClipBoard.app`
2. Open **Finder** and go to your **Downloads** folder
3. Drag `ClipBoard.app` into your **Applications** folder

   ```
   Downloads/ClipBoard.app  →  /Applications/ClipBoard.app
   ```

4. Double-click to launch — macOS may show a security prompt on first open:
   - Go to **System Settings → Privacy & Security**
   - Scroll down and click **"Open Anyway"** next to ClipBoard
5. The 📋 icon appears in your **menu bar** — you're all set

> **Note:** ClipBoard does not appear in the Dock. It runs entirely from the menu bar.

---

### Option 2 — Build from source (Xcode)

```bash
git clone <repo>
cd ClipBar/ClipBar/ClipBoard
open ClipBoard.xcodeproj
```

1. Select the `ClipBoard` scheme → **Any Mac** destination
2. `Product → Archive` (`Cmd+Shift+K` then `Cmd+B`)
3. In the Organizer window: **Distribute App → Custom → Direct Distribution → Export**
4. Drag the exported `ClipBoard.app` to `/Applications`
5. Launch it — the 📋 icon appears in your menu bar

---

## Usage

### Viewing your clipboard history

Click the **📋 icon** in the menu bar at any time to open the history panel.

```
┌─────────────────────────────────────────┐
│  📋 ClipBoard                 Clear All │  ← Header
├─────────────────────────────────────────┤
│  🗒  Hello from ChatGPT            ×   │  ← Hover to reveal ×
│  🗒  git commit -m "fix bug"       ×   │
│  🗒  https://example.com           ×   │
│  📸  Screenshot 2026-03-26.png     ×   │
├─────────────────────────────────────────┤
│  ☑ Launch at login    Limit: 20 ▲▼     │  ← Settings
│  ⏻  Quit ClipBoard                     │  ← Quit button
└─────────────────────────────────────────┘
```

### Actions

| Action | How to do it |
|---|---|
| **Open history** | Click the 📋 icon in the menu bar |
| **Copy an item** | Click any row — it's instantly back on your clipboard |
| **Delete one item** | Hover over a row → click the `×` that appears |
| **Clear all history** | Click **Clear All** in the top-right corner |
| **Change history size** | Use the `▲▼` stepper in the footer (5–100 items) |
| **Launch at login** | Check the toggle in the footer — starts silently with macOS |
| **Quit the app** | Click **Quit ClipBoard** at the bottom of the panel |

### Tips

- **Works with web apps** — when you click "Copy" in ChatGPT, GitHub, Notion, or any browser-based tool, ClipBoard captures it automatically
- **Screenshots are tracked** — take a screenshot with `Cmd+Shift+4` and it appears in your history
- **No re-adds** — copying an item from ClipBoard history back to your clipboard won't create a duplicate entry
- **Persists across restarts** — your history is saved and restored every time the app launches

---

## Permissions

ClipBoard will request these permissions on first use:

| Permission | Why |
|---|---|
| **Desktop folder access** | `ScreenshotWatcher` monitors `~/Desktop` for new screenshot files |

No network access. No keychain. No analytics. Everything stays on your machine.

---

## Changelog

### v1.1 — 2026-03-26
- **Web clipboard support** — HTML/RTF fallback captures "Copy" buttons in ChatGPT, GitHub, Notion, and other web apps
- **Fixed launch crash** — `NSApp` IUO nil crash on startup resolved via `NSApplicationDelegateAdaptor`
- **Dock icon removed** — app is now menu-bar only (fixed via `INFOPLIST_KEY_LSUIElement` in build settings)
- **Quit button** — added Quit ClipBoard to the dropdown footer
- **Naming** — unified all references from `ClipBar` → `ClipBoard`

### v1.0 — Initial release
- Clipboard text history via NSPasteboard polling
- Screenshot detection via `~/Desktop` polling
- Configurable history limit (default 20)
- Launch at login toggle
- Per-item delete and clear all
- History persisted across restarts via UserDefaults

---

## License

MIT — free to use, modify, and distribute.
