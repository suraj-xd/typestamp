import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Summons the capture panel. ⌃⇧Space by default; user-configurable in
    /// Settings.
    static let toggleCapture = Self(
        "toggleCapture",
        default: .init(.space, modifiers: [.control, .shift]))
}
