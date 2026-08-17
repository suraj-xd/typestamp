import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Summons the capture panel. ⇧⌘' by default — a right-hand symbol key
    /// with no common system binding; user-configurable in Settings.
    static let toggleCapture = Self(
        "toggleCapture",
        default: .init(.quote, modifiers: [.command, .shift]))
}
