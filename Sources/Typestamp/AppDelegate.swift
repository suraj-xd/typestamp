import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) static var shared: AppDelegate?

    private var panelController: CapturePanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        OnboardingSeeder.seedIfNeeded()
        let controller = CapturePanelController(model: .shared)
        panelController = controller
        KeyboardShortcuts.onKeyDown(for: .toggleCapture) { [weak controller] in
            controller?.toggle()
        }
    }

    func toggleCapturePanel() {
        panelController?.toggle()
    }
}
