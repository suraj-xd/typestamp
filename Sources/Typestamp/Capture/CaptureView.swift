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

/// The capture bar: `[live time] [image?] [input…] [↩]`.
struct CaptureView: View {
    @Bindable var state: CaptureState
    let onSubmit: () -> Void
    let onCancel: () -> Void

    @State private var textHeight: CGFloat = CaptureMetrics.minTextHeight

    private enum CaptureMetrics {
        static let width: CGFloat = 640
        static let minTextHeight: CGFloat = 22
        // Roughly five lines of 16pt text before scrolling kicks in.
        static let maxTextHeight: CGFloat = 110
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            liveClock

            if let image = state.image {
                imageChip(image)
            }

            textInput

            Image(systemName: "return")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(hasContent ? Color.accentColor : Color.secondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: CaptureMetrics.width)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.12))
        )
    }

    private var hasContent: Bool {
        state.image != nil
            || !state.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var liveClock: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(context.date, format: .dateTime.hour().minute().second())
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func imageChip(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.primary.opacity(0.15))
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
        .overlay(alignment: .bottom) {
            // Fade hint when the text overflows and scrolls.
            if textHeight > CaptureMetrics.maxTextHeight {
                LinearGradient(
                    colors: [.clear, Color(nsColor: .windowBackgroundColor).opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 14)
                .allowsHitTesting(false)
            }
        }
    }
}
