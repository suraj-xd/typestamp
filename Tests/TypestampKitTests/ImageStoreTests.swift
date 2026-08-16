import Foundation
import Testing

@testable import TypestampKit

@Suite("ImageStore")
struct ImageStoreTests {
    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("typestamp-tests-\(UUID().uuidString)")
    }

    @Test("init creates the directory")
    func initCreatesDirectory() throws {
        let dir = makeTempDirectory()
        _ = try ImageStore(directory: dir)
        #expect(FileManager.default.fileExists(atPath: dir.path))
    }

    @Test("saved PNG data round-trips through the returned filename")
    func savedDataRoundTrips() throws {
        let store = try ImageStore(directory: makeTempDirectory())
        let data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3])

        let filename = try store.savePNG(data)

        #expect(!filename.isEmpty)
        #expect(filename.hasSuffix(".png"))
        #expect(try Data(contentsOf: store.url(for: filename)) == data)
    }

    @Test("each save gets a unique filename")
    func filenamesAreUnique() throws {
        let store = try ImageStore(directory: makeTempDirectory())
        let a = try store.savePNG(Data([1]))
        let b = try store.savePNG(Data([2]))
        #expect(a != b)
    }
}
