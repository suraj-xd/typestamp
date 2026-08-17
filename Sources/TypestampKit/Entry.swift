import Foundation

/// A single captured log entry: text, an image, or both, stamped with the
/// moment it was captured. An entry can be a todo, which additionally
/// carries the moment it was completed (nil while still open).
public struct Entry: Codable, Equatable, Identifiable, Sendable {
    public var id: Int64?
    public var createdAt: Date
    public var text: String?
    public var imagePath: String?
    public var isTodo: Bool
    public var completedAt: Date?

    public init(
        id: Int64? = nil, createdAt: Date, text: String? = nil, imagePath: String? = nil,
        isTodo: Bool = false, completedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.imagePath = imagePath
        self.isTodo = isTodo
        self.completedAt = completedAt
    }
}
