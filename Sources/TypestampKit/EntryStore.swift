import Foundation
import GRDB

extension Entry: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "entry"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

/// The single façade over the SQLite database: saving, searching, deleting
/// and observing entries.
public final class EntryStore: Sendable {
    let dbQueue: DatabaseQueue

    public init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try Self.migrator.migrate(dbQueue)
    }

    /// An ephemeral store, used by tests.
    public static func inMemory() throws -> EntryStore {
        try EntryStore(dbQueue: DatabaseQueue())
    }

    /// The persistent store at the given file URL, creating parent
    /// directories as needed.
    public static func onDisk(at url: URL) throws -> EntryStore {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return try EntryStore(dbQueue: DatabaseQueue(path: url.path))
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "entry") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("createdAt", .datetime).notNull().indexed()
                t.column("text", .text)
                t.column("imagePath", .text)
            }
            // External-content FTS5 table, kept in sync with `entry.text`
            // by triggers that GRDB installs.
            try db.create(virtualTable: "entry_ft", using: FTS5()) { t in
                t.synchronize(withTable: "entry")
                t.tokenizer = .unicode61()
                t.column("text")
            }
        }
        migrator.registerMigration("v2-todos") { db in
            try db.alter(table: "entry") { t in
                t.add(column: "isTodo", .boolean).notNull().defaults(to: false)
                t.add(column: "completedAt", .datetime)
            }
        }
        return migrator
    }

    /// Saves a capture. Returns the stored entry, or nil when there was
    /// nothing to save (no image and no non-whitespace text).
    @discardableResult
    public func save(
        text: String?, imagePath: String? = nil, isTodo: Bool = false, at date: Date = Date()
    ) throws -> Entry? {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanText = trimmed.flatMap { $0.isEmpty ? nil : $0 }
        guard cleanText != nil || imagePath != nil else { return nil }

        return try dbQueue.write { db in
            var entry = Entry(createdAt: date, text: cleanText, imagePath: imagePath, isTodo: isTodo)
            try entry.insert(db)
            return entry
        }
    }

    /// Marks a todo done (stamping when) or reopens it. A no-op for ids
    /// that don't exist.
    public func setCompleted(id: Int64, completed: Bool, at date: Date = Date()) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE entry SET completedAt = ? WHERE id = ?",
                arguments: [completed ? date : nil, id])
        }
    }

    /// All entries, newest first. A non-empty query filters through
    /// full-text search, matching every term as a prefix.
    public func entries(matching query: String? = nil) throws -> [Entry] {
        try dbQueue.read { db in
            try Self.fetchEntries(db, matching: query)
        }
    }

    /// A live feed of `entries(matching:)` that re-emits whenever the
    /// database changes.
    public func observeEntries(matching query: String? = nil) -> AsyncValueObservation<[Entry]> {
        ValueObservation
            .tracking { db in try Self.fetchEntries(db, matching: query) }
            .values(in: dbQueue)
    }

    private static func fetchEntries(_ db: Database, matching query: String?) throws -> [Entry] {
        let trimmed = (query ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
                try Entry
                .order(Column("createdAt").desc, Column("id").desc)
                .fetchAll(db)
        }
        // FTS5Pattern sanitizes user input that raw FTS5 MATCH would
        // reject as a syntax error; nil means no searchable token.
        guard let pattern = FTS5Pattern(matchingAllPrefixesIn: trimmed) else {
            return []
        }
        return try Entry.fetchAll(
            db,
            sql: """
                SELECT entry.*
                FROM entry
                JOIN entry_ft ON entry_ft.rowid = entry.id AND entry_ft MATCH ?
                ORDER BY entry.createdAt DESC, entry.id DESC
                """,
            arguments: [pattern])
    }

    /// The number of stored entries.
    public func count() throws -> Int {
        try dbQueue.read { db in
            try Entry.fetchCount(db)
        }
    }

    public func delete(id: Int64) throws {
        _ = try dbQueue.write { db in
            try Entry.deleteOne(db, key: id)
        }
    }
}
