import AppKit
import Foundation
import TypestampKit

/// Owns the app-wide services (database, image directory) and performs
/// captures and deletions on behalf of the UI.
@MainActor
final class AppModel {
    static let shared = AppModel()

    let store: EntryStore
    let images: ImageStore

    private init() {
        do {
            let base = try FileManager.default
                .url(
                    for: .applicationSupportDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true
                )
                .appendingPathComponent("Typestamp", isDirectory: true)
            store = try EntryStore.onDisk(at: base.appendingPathComponent("typestamp.sqlite"))
            images = try ImageStore(
                directory: base.appendingPathComponent("images", isDirectory: true))
        } catch {
            // Nothing works without the database; fail loudly and early.
            fatalError("Typestamp could not open its data directory: \(error)")
        }
    }

    /// Saves a capture. Returns false when there was nothing to save.
    @discardableResult
    func capture(text: String, image: NSImage?, asTodo: Bool = false) -> Bool {
        do {
            var imagePath: String?
            if let image, let png = image.pngData() {
                imagePath = try images.savePNG(png)
            }
            return try store.save(text: text, imagePath: imagePath, isTodo: asTodo) != nil
        } catch {
            NSLog("Typestamp: capture failed: %@", String(describing: error))
            return false
        }
    }

    /// Flips a todo between open and done.
    func toggleDone(_ entry: Entry) {
        guard let id = entry.id else { return }
        do {
            try store.setCompleted(id: id, completed: entry.completedAt == nil)
        } catch {
            NSLog("Typestamp: todo toggle failed: %@", String(describing: error))
        }
    }

    func imageURL(for entry: Entry) -> URL? {
        entry.imagePath.map { images.url(for: $0) }
    }

    func delete(_ entry: Entry) {
        guard let id = entry.id else { return }
        do {
            try store.delete(id: id)
            if let path = entry.imagePath {
                try? FileManager.default.removeItem(at: images.url(for: path))
            }
        } catch {
            NSLog("Typestamp: delete failed: %@", String(describing: error))
        }
    }
}

extension NSImage {
    /// PNG-encodes the image's bitmap representation.
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
