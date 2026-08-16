import KeyboardShortcuts
import SwiftUI
import TypestampKit

/// The main window: a day-sectioned, searchable log of everything captured.
struct LogView: View {
    let model: AppModel

    @State private var searchQuery = ""
    @State private var entries: [Entry] = []

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .searchable(text: $searchQuery, prompt: "Search")
        .task(id: searchQuery) {
            do {
                for try await latest in model.store.observeEntries(matching: searchQuery) {
                    entries = latest
                }
            } catch {
                NSLog("Typestamp: log observation failed: %@", String(describing: error))
            }
        }
        .frame(minWidth: 440, minHeight: 320)
    }

    private var entryList: some View {
        List {
            ForEach(groupEntriesByDay(entries), id: \.dayStart) { section in
                Section {
                    ForEach(section.entries) { entry in
                        EntryRow(
                            entry: entry,
                            imageURL: model.imageURL(for: entry),
                            onDelete: { model.delete(entry) })
                    }
                } header: {
                    Text(sectionTitle(for: section.dayStart))
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .listStyle(.inset)
    }

    @ViewBuilder
    private var emptyState: some View {
        if searchQuery.isEmpty {
            ContentUnavailableView {
                Label("Nothing captured yet", systemImage: "clock")
            } description: {
                Text("Press \(captureShortcutDescription) anywhere to log text or an image.")
            }
        } else {
            ContentUnavailableView.search(text: searchQuery)
        }
    }

    private var captureShortcutDescription: String {
        KeyboardShortcuts.getShortcut(for: .toggleCapture)?.description ?? "⌃⇧Space"
    }
}
