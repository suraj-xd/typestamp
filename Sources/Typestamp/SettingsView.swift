import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Capture shortcut:", name: .toggleCapture)
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }
}
