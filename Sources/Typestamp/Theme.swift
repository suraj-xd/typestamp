import AppKit
import SwiftUI

/// Typestamp's visual language: warm paper, near-black ink, high-contrast
/// pill controls. The whole palette is the four hex pairs below — every
/// other color is an opacity of `ink` — so retheming means editing four
/// numbers. Dark mode inverts paper and ink.
enum Theme {
    static let paperNS = dynamic(light: 0xF2F0EC, dark: 0x1A1918)
    static let inkNS = dynamic(light: 0x1C1B19, dark: 0xEAE8E3)
    static let pillNS = dynamic(light: 0x161514, dark: 0xEAE8E3)
    static let onPillNS = dynamic(light: 0xF5F4F1, dark: 0x161514)

    static let paper = Color(nsColor: paperNS)
    static let ink = Color(nsColor: inkNS)
    static let pill = Color(nsColor: pillNS)
    static let onPill = Color(nsColor: onPillNS)

    /// Secondary text: timestamps, hints, placeholders.
    static let inkFaint = ink.opacity(0.45)
    /// Whisper-quiet: day labels, inactive glyphs.
    static let inkWhisper = ink.opacity(0.3)
    /// Borders and dividers.
    static let hairline = ink.opacity(0.12)

    private static func dynamic(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(rgb: isDark ? dark : light)
        }
    }
}

extension NSColor {
    fileprivate convenience init(rgb: UInt32) {
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1)
    }
}

/// The display size for an image preview: height capped, width following
/// the image's aspect ratio (then re-capped for panoramas), never
/// upscaling. The resulting frame hugs the image exactly, so borders and
/// clip shapes match what's visible.
func fittedSize(for image: NSImage, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
    guard image.size.width > 0, image.size.height > 0 else {
        return CGSize(width: maxHeight, height: maxHeight)
    }
    var height = min(maxHeight, image.size.height)
    var width = height * image.size.width / image.size.height
    if width > maxWidth {
        width = maxWidth
        height = width * image.size.height / image.size.width
    }
    return CGSize(width: width, height: height)
}

/// A keyboard-key rendering for shortcut hints, shared by the empty state
/// and the help popover.
struct Keycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Theme.hairline)
            )
    }
}

/// The black capsule with a live time readout — the one element shared by
/// the log window's dock and the capture bar. In a timestamp app the clock
/// is the identity, so it appears wherever a capture can happen.
struct ClockPill: View {
    var showsSeconds = false
    var height: CGFloat = 36

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Text(
                    context.date,
                    format: showsSeconds
                        ? .dateTime.hour().minute().second()
                        : .dateTime.hour().minute()
                )
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .monospacedDigit()
            }
            .foregroundStyle(Theme.onPill)
            .padding(.horizontal, 13)
            .frame(height: height)
            .background(Theme.pill, in: Capsule())
        }
    }
}
