import KeyboardShortcuts
import SwiftUI

@main
struct TypestampApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Typestamp", id: WindowID.log) {
            LogView(model: .shared)
        }
        .defaultSize(width: 560, height: 640)
        .windowStyle(.hiddenTitleBar)
        // Clamps resizing to LogView's min/max frame: entries are short
        // lines, so the window stays a compact panel, never a big screen.
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }

        MenuBarExtra("Typestamp", systemImage: "square.and.pencil") {
            MenuBarMenu()
        }
    }
}

enum WindowID {
    static let log = "log"
}

private struct MenuBarMenu: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Capture") {
            AppDelegate.shared?.toggleCapturePanel()
        }
        Button("Open Log") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: WindowID.log)
        }
        Divider()
        SettingsLink {
            Text("Settings…")
        }
        Divider()
        Button("Quit Typestamp") {
            NSApp.terminate(nil)
        }
    }
}
