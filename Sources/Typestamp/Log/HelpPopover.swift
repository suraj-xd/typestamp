import KeyboardShortcuts
import SwiftUI

/// The "?" popover: how Typestamp works, in a screenful.
struct HelpPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Typestamp")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Everything you type or paste, stamped with when.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
            }

            section(
                "Capture",
                rows: [
                    (captureShortcut, "open the capture bar anywhere"),
                    ("↩", "log it"),
                    ("⇧↩", "log it as a todo"),
                    ("⌥↩", "add a line"),
                    ("⌘V", "paste text or an image"),
                    ("esc", "dismiss without saving"),
                ])

            section(
                "Log",
                rows: [
                    ("⌘F", "search everything"),
                ])

            VStack(alignment: .leading, spacing: 6) {
                tip("Click a day at the top to see just that day.")
                tip("Hover an entry to copy it; right-click for more.")
                tip("Click a todo's box to mark it done.")
                tip("A captured link becomes a bookmark with its title.")
            }
        }
        .padding(18)
        .frame(width: 280, alignment: .leading)
        .presentationBackground(Theme.paper)
    }

    private func section(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.inkWhisper)
            ForEach(rows, id: \.1) { key, description in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Keycap(label: key)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private func tip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkFaint)
    }

    private var captureShortcut: String {
        KeyboardShortcuts.getShortcut(for: .toggleCapture)?.description ?? "⇧⌘'"
    }
}
