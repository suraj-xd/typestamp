import AppKit
// @preconcurrency: LPLinkMetadata is only Sendable-annotated in newer SDKs;
// CI's older toolchain needs the fetch treated as preconcurrency.
@preconcurrency import LinkPresentation
import SwiftUI

/// Detects a "clean link" capture: the entire text is a single http(s) URL.
/// Prose that merely contains a URL stays a normal text entry.
func cleanLinkURL(from text: String?) -> URL? {
    guard let text else { return nil }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace),
        let url = URL(string: trimmed),
        let scheme = url.scheme?.lowercased(),
        scheme == "http" || scheme == "https",
        url.host() != nil
    else { return nil }
    return url
}

/// Fetched bookmark metadata, cached per URL for the session so scrolling
/// doesn't refetch. Failures cache too (as empty), avoiding retry storms.
/// @unchecked: immutable after init, but NSImage is not Sendable-annotated
/// on older SDKs.
private final class LinkMeta: NSObject, @unchecked Sendable {
    let title: String?
    let icon: NSImage?
    /// The page's OpenGraph/hero image, when it has one.
    let image: NSImage?

    init(title: String?, icon: NSImage?, image: NSImage?) {
        self.title = title
        self.icon = icon
        self.image = image
    }
}

/// Bookmark rendering for clean-link entries: favicon and page title via
/// LinkPresentation, falling back to the bare domain while loading or when
/// offline. Clicking opens the link in the default browser.
struct LinkPreview: View {
    let url: URL
    let dimmed: Bool

    @State private var meta: LinkMeta?
    @State private var hovering = false

    @MainActor private static let cache = NSCache<NSURL, LinkMeta>()

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if let ogImage = meta?.image {
                    let size = fittedSize(for: ogImage, maxWidth: 260, maxHeight: 140)
                    Image(nsImage: ogImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Theme.hairline)
                        )
                        .opacity(dimmed ? 0.5 : 1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    favicon
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1.5 }

                    Text(title)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .underline(hovering)
                        .strikethrough(dimmed, color: Theme.inkFaint)
                        .foregroundStyle(dimmed ? Theme.inkFaint : Theme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if meta?.title != nil, let host = url.host() {
                        Text(host)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkWhisper)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(url.absoluteString)
        .task(id: url) { await load() }
    }

    private var title: String {
        meta?.title ?? url.host() ?? url.absoluteString
    }

    @ViewBuilder
    private var favicon: some View {
        if let icon = meta?.icon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            Image(systemName: "link")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 16, height: 16)
        }
    }

    private func load() async {
        if let cached = Self.cache.object(forKey: url as NSURL) {
            meta = cached
            return
        }
        let provider = LPMetadataProvider()
        provider.timeout = 8
        let metadata = try? await provider.startFetchingMetadata(for: url)
        var icon: NSImage?
        if let iconProvider = metadata?.iconProvider {
            icon = await loadImage(from: iconProvider)
        }
        var image: NSImage?
        if let imageProvider = metadata?.imageProvider {
            image = await loadImage(from: imageProvider)
        }
        let fetched = LinkMeta(title: metadata?.title, icon: icon, image: image)
        Self.cache.setObject(fetched, forKey: url as NSURL)
        meta = fetched
    }

    private func loadImage(from provider: NSItemProvider) async -> NSImage? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                continuation.resume(returning: object as? NSImage)
            }
        }
    }
}
