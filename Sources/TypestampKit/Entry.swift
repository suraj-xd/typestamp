import Foundation

/// A single captured log entry: text, an image, or both, stamped with the
/// moment it was captured.
public struct Entry: Codable, Equatable, Identifiable, Sendable {
    public var id: Int64?
    public var createdAt: Date
    public var text: String?
    public var imagePath: String?

    public init(id: Int64? = nil, createdAt: Date, text: String? = nil, imagePath: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.imagePath = imagePath
    }
}
