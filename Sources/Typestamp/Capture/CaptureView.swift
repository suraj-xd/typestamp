import AppKit
import Observation
import SwiftUI

/// The in-flight capture: what's typed and what's been pasted, shared
/// between the panel controller and the SwiftUI view.
@MainActor
@Observable
final class CaptureState {
    var text = ""
    var image: NSImage?

    func reset() {
        text = ""
        image = nil
    }
}

/// The capture bar: `[live clock pill] [image?] [input…] [↩ disc]` inside an
/// opaque paper capsule. The return disc fills ink-black once there is
/// content worth stamping.
struct CaptureView: View {
    @Bindable var state: CaptureState
    let onSubmit: (_ asTodo: Bool) -> Void
    let onCancel: () -> Void

    @State private var textHeight: CGFloat = CaptureMetrics.minTextHeight

    private enum CaptureMetrics {
        static let width: CGFloat = 640
        static let minTextHeight: CGFloat = 22
        // Roughly five lines of 15pt text before scrolling kicks in.
        static let maxTextHeight: CGFloat = 105
        // Half the bar's single-line height, so it reads as a capsule when
        // empty and a soft rounded rectangle as the text grows.
        static let cornerRadius: CGFloat = 27
    }

    var body: some View {
        // Top-aligned so the clock stays pinned at the upper left while the
        // content grows taller.
        HStack(alignment: .top, spacing: 12) {
            ClockPill(showsSeconds: true, height: 30)

            // A pasted image sits on its own line with the text below it.
            VStack(alignment: .leading, spacing: 8) {
                if let image = state.image {
                    imageChip(image)
                }
                textInput
                    // Centers a single 22pt text line against the 30pt
                    // pill, so the one-line bar looks unchanged.
                    .padding(.top, state.image == nil ? 4 : 0)
            }

            returnDisc
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: CaptureMetrics.width)
        .background(
            Theme.paper,
            in: RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CaptureMetrics.cornerRadius)
                .strokeBorder(Theme.hairline)
        )
    }

    private var hasContent: Bool {
        state.image != nil
            || !state.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var returnDisc: some View {
        ZStack {
            Circle()
                .fill(hasContent ? Theme.pill : Color.clear)
            Circle()
                .strokeBorder(Theme.hairline, lineWidth: hasContent ? 0 : 1)
            Image(systemName: "return")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(hasContent ? Theme.onPill : Theme.inkWhisper)
        }
        .frame(width: 30, height: 30)
        .animation(.easeOut(duration: 0.15), value: hasContent)
        .help("Return logs it · Shift-Return logs a todo · Option-Return adds a line")
    }

    private func imageChip(_ image: NSImage) -> some View {
        // An exact frame from the image's aspect ratio, so the border hugs
        // the image instead of stretching to a max width.
        let size = fittedSize(for: image, maxWidth: 380, maxHeight: 120)
        return Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Theme.hairline)
            )
            .onTapGesture { state.image = nil }
            .help("Click to remove the image")
    }

    private var textInput: some View {
        CaptureTextView(
            text: $state.text,
            contentHeight: $textHeight,
            onImagePaste: { state.image = $0 },
            onSubmit: onSubmit,
            onCancel: onCancel
        )
        .frame(
            height: min(
                max(textHeight, CaptureMetrics.minTextHeight),
                CaptureMetrics.maxTextHeight)
        )
        .overlay(alignment: .topLeading) {
            if state.text.isEmpty && state.image == nil {
                Text("Type or paste…")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkWhisper)
                    // Clears the insertion point blinking at x = 0.
                    .padding(.top, 2)
                    .padding(.leading, 3)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            // Fade hint when the text overflows and scrolls.
            if textHeight > CaptureMetrics.maxTextHeight {
                LinearGradient(
                    colors: [Theme.paper.opacity(0), Theme.paper.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 14)
                .allowsHitTesting(false)
            }
        }
    }
}
