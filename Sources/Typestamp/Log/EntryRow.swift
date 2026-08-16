import AppKit
import SwiftUI
import TypestampKit

/// One log line: gray timestamp on the left, content on the right.
struct EntryRow: View {
    let entry: Entry
    let imageURL: URL?
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.createdAt, format: .dateTime.hour().minute())
                .font(.system(.callout, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                if let text = entry.text {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let imageURL {
                    EntryImage(url: imageURL)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if let text = entry.text {
                Button("Copy Text") {
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
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 180, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary.opacity(0.1))
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
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
