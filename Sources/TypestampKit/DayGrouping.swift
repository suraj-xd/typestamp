import Foundation

/// Entries of one calendar day, for the sectioned log view.
public struct DaySection: Equatable, Sendable {
    public let dayStart: Date
    public let entries: [Entry]

    public init(dayStart: Date, entries: [Entry]) {
        self.dayStart = dayStart
        self.entries = entries
    }
}

/// Groups entries (assumed newest first) into calendar-day sections,
/// newest day first.
public func groupEntriesByDay(
    _ entries: [Entry], calendar: Calendar = .current
) -> [DaySection] {
    var sections: [DaySection] = []
    var currentDay: Date?
    var currentEntries: [Entry] = []

    for entry in entries {
        let day = calendar.startOfDay(for: entry.createdAt)
        if day == currentDay {
            currentEntries.append(entry)
        } else {
            if let currentDay {
                sections.append(DaySection(dayStart: currentDay, entries: currentEntries))
            }
            currentDay = day
            currentEntries = [entry]
        }
    }
    if let currentDay {
        sections.append(DaySection(dayStart: currentDay, entries: currentEntries))
    }
    return sections
}

/// "Today", "Yesterday", or a short date like "Aug 15" ("Aug 15, 2025" when
/// the year differs from the current one).
public func sectionTitle(
    for dayStart: Date, calendar: Calendar = .current, now: Date = Date()
) -> String {
    if calendar.isDate(dayStart, inSameDayAs: now) {
        return String(localized: "Today")
    }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
        calendar.isDate(dayStart, inSameDayAs: yesterday)
    {
        return String(localized: "Yesterday")
    }

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = calendar.locale ?? .current
    let sameYear = calendar.component(.year, from: dayStart) == calendar.component(.year, from: now)
    formatter.setLocalizedDateFormatFromTemplate(sameYear ? "MMMd" : "yMMMd")
    return formatter.string(from: dayStart)
}
