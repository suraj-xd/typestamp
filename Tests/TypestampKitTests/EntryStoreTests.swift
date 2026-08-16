import Foundation
import Testing

@testable import TypestampKit

@Suite("EntryStore")
struct EntryStoreTests {
    // Whole-second dates so SQLite datetime round-trips compare exactly.
    private func date(_ secondsAgo: TimeInterval) -> Date {
        Date(timeIntervalSince1970: (1_755_000_000 - secondsAgo).rounded())
    }

    @Test("saved entry round-trips with its timestamp")
    func savedEntryRoundTrips() throws {
        let store = try EntryStore.inMemory()
        let captured = date(0)

        let saved = try store.save(text: "hello world", at: captured)

        let all = try store.entries()
        #expect(all.count == 1)
        #expect(all[0].text == "hello world")
        #expect(all[0].createdAt == captured)
        #expect(all[0].id != nil)
        #expect(saved?.id == all[0].id)
    }

    @Test("entries come back newest first")
    func entriesAreNewestFirst() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "oldest", at: date(300))
        try store.save(text: "newest", at: date(0))
        try store.save(text: "middle", at: date(150))

        let texts = try store.entries().map(\.text)
        #expect(texts == ["newest", "middle", "oldest"])
    }

    @Test("whitespace-only capture saves nothing")
    func whitespaceOnlyCaptureSavesNothing() throws {
        let store = try EntryStore.inMemory()

        let saved = try store.save(text: "   \n\t  ", at: date(0))

        #expect(saved == nil)
        #expect(try store.entries().isEmpty)
    }

    @Test("text is trimmed before storing")
    func textIsTrimmed() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "  hello  \n", at: date(0))
        #expect(try store.entries().first?.text == "hello")
    }

    @Test("image-only capture is a valid entry")
    func imageOnlyCaptureIsValid() throws {
        let store = try EntryStore.inMemory()

        let saved = try store.save(text: nil, imagePath: "abc.png", at: date(0))

        #expect(saved?.imagePath == "abc.png")
        #expect(saved?.text == nil)
        #expect(try store.entries().count == 1)
    }

    @Test("search matches word prefixes")
    func searchMatchesPrefixes() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "hello world", at: date(10))
        try store.save(text: "goodbye moon", at: date(0))

        let results = try store.entries(matching: "hel")
        #expect(results.map(\.text) == ["hello world"])
    }

    @Test("search is case-insensitive")
    func searchIsCaseInsensitive() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "hello world", at: date(0))

        #expect(try store.entries(matching: "WORLD").count == 1)
    }

    @Test("multi-term search requires all terms")
    func multiTermSearchRequiresAllTerms() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "hello world", at: date(10))
        try store.save(text: "hello moon", at: date(0))

        let results = try store.entries(matching: "hello wor")
        #expect(results.map(\.text) == ["hello world"])
    }

    @Test("search results keep newest-first order")
    func searchResultsAreNewestFirst() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "note one", at: date(300))
        try store.save(text: "note two", at: date(0))

        let results = try store.entries(matching: "note")
        #expect(results.map(\.text) == ["note two", "note one"])
    }

    @Test("search never matches image-only entries")
    func searchSkipsImageOnlyEntries() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: nil, imagePath: "shot.png", at: date(10))
        try store.save(text: "shot of espresso", at: date(0))

        let results = try store.entries(matching: "shot")
        #expect(results.map(\.text) == ["shot of espresso"])
    }

    @Test("FTS syntax characters in the query are harmless")
    func ftsSyntaxIsSanitized() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "hello world", at: date(0))

        // Raw FTS5 would reject these queries with a syntax error.
        #expect(try store.entries(matching: #"hello ("#).count == 1)
        #expect(try store.entries(matching: #""hello"#).count == 1)
        // Sanitized to the token "near", which simply matches nothing.
        #expect(try store.entries(matching: "NEAR(").isEmpty)
    }

    @Test("empty and nil queries return everything")
    func emptyQueryReturnsAll() throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "one", at: date(10))
        try store.save(text: nil, imagePath: "img.png", at: date(0))

        #expect(try store.entries(matching: nil).count == 2)
        #expect(try store.entries(matching: "").count == 2)
        #expect(try store.entries(matching: "   ").count == 2)
    }

    @Test(
        "observation emits current entries, then updates after each save", .timeLimit(.minutes(1)))
    func observationEmitsUpdates() async throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "first", at: date(10))

        var iterator = store.observeEntries(matching: nil).makeAsyncIterator()
        let initial = try await iterator.next()
        #expect(initial?.map(\.text) == ["first"])

        try store.save(text: "second", at: date(0))
        let updated = try await iterator.next()
        #expect(updated?.map(\.text) == ["second", "first"])
    }

    @Test("observation respects the search query", .timeLimit(.minutes(1)))
    func observationRespectsQuery() async throws {
        let store = try EntryStore.inMemory()
        try store.save(text: "apple pie", at: date(10))
        try store.save(text: "banana bread", at: date(0))

        var iterator = store.observeEntries(matching: "app").makeAsyncIterator()
        let results = try await iterator.next()
        #expect(results?.map(\.text) == ["apple pie"])
    }

    @Test("delete removes the entry from the log and from search")
    func deleteRemovesEverywhere() throws {
        let store = try EntryStore.inMemory()
        let saved = try store.save(text: "delete me", at: date(0))
        let id = try #require(saved?.id)

        try store.delete(id: id)

        #expect(try store.entries().isEmpty)
        #expect(try store.entries(matching: "delete").isEmpty)
    }
}
