import AppKit
import SwiftUI
import TypestampKit

/// One log line: faint monospaced timestamp on the left, ink content on the
/// right. Hovering tints the row so the right-click affordance is findable.
struct EntryRow: View {
    let entry: Entry
    let imageURL: URL?
    let onToggleDone: () -> Void
    let onDelete: () -> Void

    @State private var hovering = false
    @State private var copied = false

    private var isDone: Bool { entry.completedAt != nil }
    private var linkURL: URL? { cleanLinkURL(from: entry.text) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(entry.createdAt, format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Theme.inkFaint)
                // Fixed column so one- and two-digit hours don't wobble the
                // text edge; trailing keeps times snug against it.
                .frame(width: 64, alignment: .trailing)
                // Optically aligns the 12pt cap height with the 15pt body's.
                .padding(.top, 2.5)

            if entry.isTodo {
                todoCheckbox
            }

            VStack(alignment: .leading, spacing: 8) {
                if let linkURL {
                    LinkPreview(url: linkURL, dimmed: isDone)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let text = entry.text {
                    Text(text)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .strikethrough(isDone, color: Theme.inkFaint)
                        .foregroundStyle(isDone ? Theme.inkFaint : Theme.ink)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let imageURL {
                    EntryImage(url: imageURL)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.ink.opacity(hovering ? 0.04 : 0),
            in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            if hovering || copied {
                copyButton
            }
        }
        .onHover { hovering = $0 }
        .contextMenu {
            if entry.isTodo {
                Button(isDone ? "Reopen" : "Mark Done", action: onToggleDone)
                Divider()
            }
            if let linkURL {
                Button("Open Link") { NSWorkspace.shared.open(linkURL) }
            }
            if let text = entry.text {
                Button(linkURL == nil ? "Copy Text" : "Copy Link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
            }
            if let imageURL {
                Button("Copy Image") {
                    if let image = NSImage(contentsOf: imageURL) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.writeObjects([image])
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var todoCheckbox: some View {
        Button(action: onToggleDone) {
            Image(systemName: isDone ? "checkmark.square.fill" : "square")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isDone ? Theme.ink : Theme.inkFaint)
        }
        .buttonStyle(.plain)
        .padding(.top, 1)
        .help(isDone ? "Reopen" : "Mark done")
    }

    /// Appears on hover; copies the text (or the image for image-only
    /// entries) and flashes a checkmark as confirmation.
    private var copyButton: some View {
        Button {
            copyEntry()
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(copied ? Theme.ink : Theme.inkFaint)
                .frame(width: 24, height: 24)
                .background(Theme.paper)
                .overlay(Rectangle().strokeBorder(Theme.hairline))
        }
        .buttonStyle(.plain)
        .help(copied ? "Copied" : "Copy")
        .padding(.top, 4)
        .padding(.trailing, 4)
    }

    private func copyEntry() {
        NSPasteboard.general.clearContents()
        if let text = entry.text {
            NSPasteboard.general.setString(text, forType: .string)
        } else if let imageURL, let image = NSImage(contentsOf: imageURL) {
            NSPasteboard.general.writeObjects([image])
        }
    }
}

/// Loads an entry's image off the main thread, with a small shared cache so
/// scrolling doesn't re-read files.
struct EntryImage: View {
    let url: URL

    @State private var image: NSImage?

    @MainActor private static let cache = NSCache<NSURL, NSImage>()

    var body: some View {
        Group {
            if let image {
                let size = fittedSize(for: image, maxWidth: 320, maxHeight: 180)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Theme.hairline)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.ink.opacity(0.05))
                    .frame(width: 160, height: 90)
            }
        }
        .task(id: url) {
            if let cached = Self.cache.object(forKey: url as NSURL) {
                image = cached
                return
            }
            let data = await Task.detached { [url] in try? Data(contentsOf: url) }.value
            guard let data, let loaded = NSImage(data: data) else { return }
            Self.cache.setObject(loaded, forKey: url as NSURL)
            image = loaded
        }
    }
}
