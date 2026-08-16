import Foundation
import Testing

@testable import TypestampKit

@Suite("Day grouping")
struct DayGroupingTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    // Fixed clock: 2026-08-17 15:00:00 UTC.
    private var now: Date {
        calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 17, hour: 15))!
    }

    private func entry(daysAgo: Int, hour: Int, text: String) -> Entry {
        let dayStart = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -daysAgo, to: now)!)
        let at = calendar.date(byAdding: .hour, value: hour, to: dayStart)!
        return Entry(id: Int64(text.hashValue), createdAt: at, text: text)
    }

    @Test("groups entries into calendar-day sections, newest day first")
    func groupsByDayNewestFirst() {
        let entries = [
            entry(daysAgo: 0, hour: 14, text: "today-later"),
            entry(daysAgo: 0, hour: 9, text: "today-earlier"),
            entry(daysAgo: 1, hour: 22, text: "yesterday"),
            entry(daysAgo: 5, hour: 8, text: "last-week"),
        ]

        let sections = groupEntriesByDay(entries, calendar: calendar)

        #expect(sections.count == 3)
        #expect(sections[0].entries.map(\.text) == ["today-later", "today-earlier"])
        #expect(sections[1].entries.map(\.text) == ["yesterday"])
        #expect(sections[2].entries.map(\.text) == ["last-week"])
        #expect(sections[0].dayStart > sections[1].dayStart)
        #expect(sections[1].dayStart > sections[2].dayStart)
    }

    @Test("section day starts are midnight of that day")
    func dayStartsAreMidnight() {
        let sections = groupEntriesByDay(
            [entry(daysAgo: 0, hour: 14, text: "x")], calendar: calendar)
        #expect(sections.first?.dayStart == calendar.startOfDay(for: now))
    }

    @Test("empty input yields no sections")
    func emptyInput() {
        #expect(groupEntriesByDay([], calendar: calendar).isEmpty)
    }

    @Test("titles: Today, Yesterday, then short dates")
    func titles() {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let sameYear = calendar.date(byAdding: .day, value: -10, to: today)!  // Aug 7, 2026
        let lastYear = calendar.date(byAdding: .year, value: -1, to: sameYear)!  // Aug 7, 2025

        #expect(sectionTitle(for: today, calendar: calendar, now: now) == "Today")
        #expect(sectionTitle(for: yesterday, calendar: calendar, now: now) == "Yesterday")
        #expect(sectionTitle(for: sameYear, calendar: calendar, now: now) == "Aug 7")
        #expect(sectionTitle(for: lastYear, calendar: calendar, now: now) == "Aug 7, 2025")
    }
}
