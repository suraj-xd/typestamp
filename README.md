# Typestamp

A tiny macOS app for capturing timestamped notes without breaking flow.

Press **⌃⇧Space** anywhere. A capture bar appears over whatever you're doing —
the app you were in keeps focus. Type something, or paste text or an image.
Press **Enter**. It's logged with a timestamp and the bar is gone.

```
[ 1:43:07 ] [ your text or pasted image…              ] [↩]
```

The main window shows everything you've captured, grouped by day, with
full-text search that filters as you type.

## Features

- Global shortcut summons a Spotlight-style capture bar (non-activating —
  your current app keeps focus)
- Capture text, images, or both; Shift+Enter for multi-line notes
- Day-grouped log with instant search (SQLite FTS5, prefix matching)
- Local only. Everything lives in `~/Library/Application Support/Typestamp/`
- Native Swift, no Electron, no webview — the app is a few megabytes

## Install

Build from source (requires Xcode 16 or later):

```sh
git clone https://github.com/suraj-xd/typestamp
cd typestamp
make install   # builds dist/Typestamp.app and copies it to /Applications
```

Or `make run` to build and launch without installing.

## Usage

| Key | Action |
| --- | --- |
| ⌃⇧Space | Open / close the capture bar (change it in Settings) |
| Enter | Log the capture and dismiss |
| Shift+Enter | New line |
| Esc / click away | Dismiss without logging |
| ⌘V | Paste — images become an attachment chip; click the chip to remove |

## Development

```sh
swift test            # unit tests (Swift Testing)
swift build           # debug build
make app              # release build + .app bundle in dist/
swift format lint --strict --recursive Sources Tests Package.swift
```

The package has two targets:

- **TypestampKit** — storage and logic: GRDB/SQLite with an FTS5 index,
  day grouping, image store. Fully unit-tested.
- **Typestamp** — the app: an `NSPanel` (`.nonactivatingPanel`) hosting the
  SwiftUI capture bar, the log window, menu bar item, and settings.

Dependencies: [GRDB](https://github.com/groue/GRDB.swift) and
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).

Design notes live in [docs/plans](docs/plans/).

## License

[MIT](LICENSE)
