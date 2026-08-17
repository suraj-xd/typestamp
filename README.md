# Typestamp

Everything you type or paste, stamped with when.

Typestamp is a tiny macOS capture app. Press <kbd>⇧⌘'</kbd> anywhere, type or
paste, hit <kbd>Return</kbd> — it's in the log with a timestamp. The log is a
searchable, day-grouped journal of everything you've ever captured.

## Features

- **Spotlight-style capture** — a floating bar summoned over any app with a
  global hotkey (<kbd>⇧⌘'</kbd> by default, configurable in Settings)
- **Todos** — <kbd>⇧↩</kbd> logs a capture as a todo; click its box to mark
  it done
- **Images** — paste a screenshot or image straight into the bar
- **Bookmarks** — capture a link and it renders with its favicon, page
  title, and OpenGraph preview
- **Search & filter** — full-text search over everything (SQLite FTS5),
  plus a one-click day filter
- **Local-first** — one SQLite file and plain PNGs in
  `~/Library/Application Support/Typestamp`; no account, no sync, no
  telemetry
- **Minimal paper-and-ink UI** — light and dark

## Keyboard

| Keys | Action |
| --- | --- |
| <kbd>⇧⌘'</kbd> | Open the capture bar anywhere |
| <kbd>↩</kbd> | Log it |
| <kbd>⇧↩</kbd> | Log it as a todo |
| <kbd>⌥↩</kbd> | Add a line |
| <kbd>esc</kbd> | Dismiss without saving |
| <kbd>⌘F</kbd> | Search the log |

## Install

Grab the DMG from [Releases](https://github.com/suraj-xd/typestamp/releases)
and drag Typestamp to Applications.

> The app is not yet notarized: the first launch needs a right-click →
> **Open** to get past Gatekeeper.

### Build from source

Requires macOS 14+ and Xcode 16+.

```sh
git clone https://github.com/suraj-xd/typestamp.git
cd typestamp
make install   # builds dist/Typestamp.app and copies it to /Applications
```

## Development

Two SwiftPM targets: `TypestampKit` (storage — GRDB/SQLite with FTS5, fully
tested) and `Typestamp` (the app — SwiftUI plus an AppKit capture panel).

```sh
make test    # run the test suite
make app     # build dist/Typestamp.app
make run     # build and launch
scripts/make-icon.sh   # regenerate the icns after changing Assets/icon.png
scripts/make-dmg.sh    # build a distributable DMG into dist/
```

## License

[MIT](LICENSE)
