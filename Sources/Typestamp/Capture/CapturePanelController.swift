import AppKit
import SwiftUI

/// A borderless panel that can become the key window without activating the
/// app — the previous app stays frontmost while we receive keystrokes. This
/// is the same mechanism Spotlight and Raycast use.
private final class CapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the capture panel: summoning, positioning, dismissal, and handing
/// finished captures to the model.
@MainActor
final class CapturePanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let model: AppModel
    private let state = CaptureState()

    init(model: AppModel) {
        self.model = model
        panel = CapturePanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true)
        super.init()

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        let view = CaptureView(
            state: state,
            onSubmit: { [weak self] in self?.submit() },
            onCancel: { [weak self] in self?.hide() })
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = .preferredContentSize
        panel.contentViewController = hosting
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        state.reset()
        position()
        panel.makeKeyAndOrderFront(nil)
        // The SwiftUI hierarchy materializes its NSTextView during the
        // ordering-front layout pass; focus it right after.
        DispatchQueue.main.async { [weak self] in
            self?.focusTextView()
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func submit() {
        model.capture(text: state.text, image: state.image)
        hide()
    }

    /// Centered on the screen with the mouse, about a third from the top.
    private func position() {
        guard let screen = screenWithMouse() else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(
            NSPoint(
                x: frame.midX - size.width / 2,
                y: frame.minY + frame.height * 0.7 - size.height))
    }

    private func screenWithMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
    }

    private func focusTextView() {
        guard let contentView = panel.contentView,
            let textView = firstTextView(in: contentView)
        else { return }
        panel.makeFirstResponder(textView)
    }

    private func firstTextView(in view: NSView) -> NSTextView? {
        if let textView = view as? NSTextView { return textView }
        for subview in view.subviews {
            if let found = firstTextView(in: subview) { return found }
        }
        return nil
    }

    // Click-away or any other focus loss dismisses without saving.
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
