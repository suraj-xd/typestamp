import AppKit
import SwiftUI

/// Plain-text editor for the capture bar, wrapping NSTextView so we can
/// intercept image pastes and the Enter/Shift+Enter/Esc keys — none of
/// which SwiftUI's TextEditor exposes.
struct CaptureTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var contentHeight: CGFloat
    let onImagePaste: (NSImage) -> Void
    /// Called on Enter; the flag is true for Shift+Enter, which logs the
    /// capture as a todo.
    let onSubmit: (_ asTodo: Bool) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PasteCatchingTextView()
        textView.delegate = context.coordinator
        textView.onImagePaste = { context.coordinator.parent.onImagePaste($0) }
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = Theme.inkNS
        textView.insertionPointColor = Theme.inkNS
        textView.isRichText = false
        textView.drawsBackground = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? PasteCatchingTextView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.recomputeHeight(of: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CaptureTextView

        init(_ parent: CaptureTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            recomputeHeight(of: textView)
        }

        func recomputeHeight(of textView: NSTextView) {
            guard let container = textView.textContainer,
                let layoutManager = textView.layoutManager
            else { return }
            layoutManager.ensureLayout(for: container)
            let height =
                layoutManager.usedRect(for: container).height
                + textView.textContainerInset.height * 2
            if parent.contentHeight != height {
                let parent = parent
                // Defer: mutating SwiftUI state during AppKit layout is
                // undefined behavior.
                DispatchQueue.main.async {
                    parent.contentHeight = height
                }
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                // Enter logs, Shift+Enter logs a todo, Option+Enter inserts
                // a newline.
                let modifiers = NSApp.currentEvent?.modifierFlags ?? []
                if modifiers.contains(.option) {
                    return false
                }
                parent.onSubmit(modifiers.contains(.shift))
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            default:
                return false
            }
        }
    }
}

/// NSTextView that routes pasted images to a callback instead of inserting
/// them into the text.
final class PasteCatchingTextView: NSTextView {
    var onImagePaste: ((NSImage) -> Void)?

    /// The capture panel is non-activating, so the app's Edit menu — which
    /// normally resolves ⌘V/⌘C/etc. — is never installed. Handle the
    /// standard editing equivalents here, like every Spotlight-style panel
    /// must.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown else {
            return super.performKeyEquivalent(with: event)
        }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased()
        switch (modifiers, key) {
        case ([.command], "v"): paste(nil)
        case ([.command], "c"): copy(nil)
        case ([.command], "x"): cut(nil)
        case ([.command], "a"): selectAll(nil)
        case ([.command], "z"): undoManager?.undo()
        case ([.command, .shift], "z"): undoManager?.redo()
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }

    override func paste(_ sender: Any?) {
        if let image = Self.image(from: .general) {
            onImagePaste?(image)
            return
        }
        super.paste(sender)
    }

    /// An image on the pasteboard wins over any accompanying text (browser
    /// image copies carry both). Plain text never decodes as an image.
    private static func image(from pasteboard: NSPasteboard) -> NSImage? {
        if pasteboard.availableType(from: [.tiff, .png]) != nil {
            return NSImage(pasteboard: pasteboard)
        }
        // Image files copied in Finder arrive as file URLs.
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
            let url = urls.first,
            let image = NSImage(contentsOf: url),
            image.isValid
        {
            return image
        }
        return nil
    }
}
