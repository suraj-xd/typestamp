# Typestamp — Design

**Date:** 2026-08-17
**Status:** Validated with user

## What it is

A minimal, fast, local macOS app for capturing timestamped notes. A global
shortcut (default **⌃⇧Space**) summons a Spotlight-style capture bar; you type
or paste (text and/or an image), press **Enter**, and it's logged with a
timestamp. The main window shows a day-grouped log with full-text search.

Decisions made during design:

- **Stack:** native Swift (SwiftUI + AppKit), not Tauri. The non-activating
  panel is a first-class AppKit primitive; Tauri needs Obj-C bridging plugins
  to emulate it. macOS-only removes Tauri's cross-platform advantage.
- **Hotkey:** ⌃⇧Space default, user-configurable via KeyboardShortcuts.
- **App style:** menu bar icon **and** regular Dock presence.

## Architecture

One process, three pieces:

### 1. Capture panel

- `NSPanel` subclass: `.nonactivatingPanel` + `.borderless`, floating window
  level, centered horizontally ~1/3 from the top of the screen with the mouse.
  The previous app stays frontmost; the panel receives keystrokes.
- Layout: `[live time] [ input field … ] [↩]`. The time shown is the timestamp
  the entry will get.
- Input is an `NSTextView` wrapped for SwiftUI so we can intercept:
  - **paste of an image** → captured as an inline thumbnail attachment
  - **Enter** → save + close; **Shift+Enter** → newline
  - **Esc** / click outside / focus loss → close without saving
  - Empty Enter → just close.
- An entry may have text, an image, or both.

### 2. Storage

- SQLite via **GRDB** at `~/Library/Application Support/Typestamp/typestamp.sqlite`.
- `entry(id, createdAt, text, imagePath)` + an **FTS5** virtual table
  synchronized with `entry.text` for instant full-text search with prefix
  matching (`FTS5Pattern(matchingAllPrefixesIn:)` sanitizes user queries).
- Images are PNG files in `Application Support/Typestamp/images/`; only the
  relative filename is stored in the DB.
- `EntryStore` is the single façade: `save`, `entries(matching:)`, `delete`.
  UI observes it via GRDB's `ValueObservation` so the log live-updates.

### 3. Log window

- SwiftUI window from the menu bar icon or Dock: sections per day ("Today",
  "Yesterday", "Aug 15"), rows = gray timestamp left, content right, image
  thumbnails inline. Search field filters live through FTS5.
- Day grouping is a pure function (`Calendar` injected) so it's unit-testable.

## Error handling

- DB open failure is fatal at launch (nothing works without it) with a clear
  message; save failures are logged and surfaced, never crash the panel.
- Image decode failures fall back to a text-only entry rather than dropping
  the capture.

## Testing

- **Unit (Swift Testing):** `EntryStore` CRUD + FTS search behavior against
  in-memory databases; day-grouping and query-building pure functions.
- **Manual:** panel summon/dismiss/focus behavior (AppKit window management is
  not meaningfully unit-testable).
- CI: GitHub Actions on macOS runners — build + `swift test`.

## Distribution

- Built with SwiftPM; `scripts/bundle.sh` assembles `Typestamp.app` (Info.plist,
  resource bundles, ad-hoc codesign). No Xcode project committed.
