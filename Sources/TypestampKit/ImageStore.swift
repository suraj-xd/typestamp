import Foundation

/// Flat directory of captured images. The database stores only filenames
/// returned from here, never absolute paths.
public struct ImageStore: Sendable {
    public let directory: URL

    /// Creates the directory if needed.
    public init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Writes PNG data under a fresh unique filename and returns it.
    public func savePNG(_ data: Data) throws -> String {
        let filename = UUID().uuidString.lowercased() + ".png"
        try data.write(to: url(for: filename), options: .atomic)
        return filename
    }

    public func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }
}
