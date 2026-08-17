import KeyboardShortcuts
import SwiftUI
import TypestampKit

/// The main window: a day-sectioned, searchable log of everything captured,
/// styled as a paper logbook. Controls live in a pill dock floating over the
/// bottom edge; entries scroll underneath it through a paper fade.
struct LogView: View {
    let model: AppModel

    @State private var searchQuery = ""
    @State private var entries: [Entry] = []
    @State private var selectedDay: Date?
    @State private var showHelp = false
    @FocusState private var searchFocused: Bool

    private var sections: [DaySection] {
        groupEntriesByDay(entries)
    }

    private var visibleSections: [DaySection] {
        guard let selectedDay else { return sections }
        return sections.filter { $0.dayStart == selectedDay }
    }

    var body: some View {
        VStack(spacing: 0) {
            if sections.count > 1 {
                dayStrip
            }
            if entries.isEmpty {
                emptyState
            } else if visibleSections.isEmpty {
                daySelectionEmpty
            } else {
                entryList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .overlay(alignment: .bottom) { dock }
        .overlay(alignment: .topTrailing) {
            helpButton
                .padding(.top, 20)
                .padding(.trailing, 16)
        }
        .task(id: searchQuery) {
            do {
                for try await latest in model.store.observeEntries(matching: searchQuery) {
                    entries = latest
                    // A day filter outlives a search (results may return),
                    // but not the day's last entry being deleted.
                    if let day = selectedDay, searchQuery.isEmpty,
                        !latest.contains(where: {
                            Calendar.current.startOfDay(for: $0.createdAt) == day
                        })
                    {
                        selectedDay = nil
                    }
                }
            } catch {
                NSLog("Typestamp: log observation failed: %@", String(describing: error))
            }
        }
        .frame(
            minWidth: 440, idealWidth: 560, maxWidth: 760,
            minHeight: 360, idealHeight: 640, maxHeight: 900)
    }

    // MARK: - Entry list

    private var entryList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(visibleSections, id: \.dayStart) { section in
                    dayLabel(for: section.dayStart)
                    ForEach(section.entries) { entry in
                        EntryRow(
                            entry: entry,
                            imageURL: model.imageURL(for: entry),
                            onToggleDone: { model.toggleDone(entry) },
                            onDelete: { model.delete(entry) })
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 20)
            .padding(.bottom, 96)
            // A book-like measure: the log column caps out and centers
            // instead of stretching lines across a wide window.
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Day strip

    /// Squared blocks of recent days, one per day with entries. Clicking a
    /// day shows only that day; clicking it again shows all days.
    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(sections, id: \.dayStart) { section in
                    dayBlock(for: section.dayStart)
                }
            }
            .padding(.horizontal, 24)
        }
        // Centering must wrap the scroll view, not its content — inside a
        // horizontal ScrollView a maxWidth frame resolves to content size.
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.bottom, 4)
    }

    private func dayBlock(for dayStart: Date) -> some View {
        let isSelected = selectedDay == dayStart
        return Button {
            selectedDay = isSelected ? nil : dayStart
        } label: {
            Text(sectionTitle(for: dayStart))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? Theme.onPill : Theme.inkFaint)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.pill : Color.clear)
        }
        .buttonStyle(.plain)
        .help(isSelected ? "Show all days" : "Show only this day")
    }

    private var daySelectionEmpty: some View {
        VStack(spacing: 6) {
            Text("No matches that day")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.ink)
            Text("Nothing from the selected day contains “\(searchQuery)”.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dayLabel(for dayStart: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .medium))
            Text(sectionTitle(for: dayStart).uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
        }
        .foregroundStyle(Theme.inkWhisper)
        .padding(.horizontal, 10)
        .padding(.top, 26)
        .padding(.bottom, 8)
    }

    // MARK: - Floating dock

    private var dock: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Theme.paper.opacity(0), Theme.paper],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 90)
            .allowsHitTesting(false)

            HStack(spacing: 8) {
                ClockPill()
                    .help("Current time — every capture is stamped with it")
                searchPill
                captureButton
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    private var searchPill: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkFaint)
            TextField("Search", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)
                .focused($searchFocused)
                .onExitCommand {
                    searchQuery = ""
                    searchFocused = false
                }
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(Theme.paper, in: Capsule())
        .overlay(
            Capsule().strokeBorder(
                searchFocused ? Theme.ink.opacity(0.35) : Theme.hairline)
        )
        .background {
            // Invisible target so ⌘F focuses the search field.
            Button("") { searchFocused = true }
                .keyboardShortcut("f", modifiers: .command)
                .opacity(0)
        }
    }

    private var captureButton: some View {
        Button {
            AppDelegate.shared?.toggleCapturePanel()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.onPill)
                .frame(width: 36, height: 36)
                .background(Theme.pill, in: Circle())
        }
        .buttonStyle(.plain)
        .help("New capture (\(captureShortcutDescription))")
    }

    private var helpButton: some View {
        Button {
            showHelp.toggle()
        } label: {
            Image(systemName: "questionmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 22, height: 22)
                .background(Circle().strokeBorder(Theme.hairline))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("How Typestamp works")
        .popover(isPresented: $showHelp, arrowEdge: .bottom) {
            HelpPopover()
        }
    }

    // MARK: - Empty states

    @ViewBuilder
    private var emptyState: some View {
        if searchQuery.isEmpty {
            VStack(spacing: 20) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date, format: .dateTime.hour().minute().second())
                        .font(.system(size: 44, weight: .light, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                }
                HStack(spacing: 6) {
                    Text("Press")
                    Keycap(label: captureShortcutDescription)
                    Text("anywhere to capture")
                }
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkFaint)
            }
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 6) {
                Text("No matches")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text("Nothing logged contains “\(searchQuery)”.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var captureShortcutDescription: String {
        KeyboardShortcuts.getShortcut(for: .toggleCapture)?.description ?? "⇧⌘'"
    }
}
