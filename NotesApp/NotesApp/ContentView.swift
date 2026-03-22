import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: NotesViewModel
    @State private var newNoteText = ""
    @State private var searchText = ""

    init(apiService: APIServiceProtocol = APIService.shared) {
        _viewModel = StateObject(wrappedValue: NotesViewModel(apiService: apiService))
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var filteredNotes: [Note] {
        var result = viewModel.notes
        if viewModel.showFavoritesOnly {
            result = result.filter { $0.isFavorited }
        }
        if !trimmedSearch.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(trimmedSearch) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NotesCounterView(
                    totalCount: viewModel.notes.count,
                    filteredCount: (trimmedSearch.isEmpty && !viewModel.showFavoritesOnly) ? nil : filteredNotes.count
                )
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                List {
                    ForEach(filteredNotes) { note in
                        HStack {
                            Text(note.title)
                            Spacer()
                            Button {
                                viewModel.toggleFavorite(note: note)
                            } label: {
                                Image(systemName: note.isFavorited ? "star.fill" : "star")
                                    .foregroundColor(note.isFavorited ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("favorite_button_\(note.id)")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteNote(id: note.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.interactively)
                .accessibilityIdentifier("notes_list")

                HStack {
                    TextField(NSLocalizedString("notes_new_note_placeholder", comment: "New note placeholder"), text: $newNoteText)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(
                            NSLocalizedString("notes_new_note_field", comment: "New note text field")
                        )
                        .accessibilityIdentifier("new_note_text_field")

                    Button {
                        guard !newNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let title = newNoteText
                        newNoteText = ""
                        Task { await viewModel.addNote(title: title) }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel(
                        NSLocalizedString("notes_add_button", comment: "Add note button")
                    )
                    .accessibilityIdentifier("add_note_button")
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("notes_navigation_title", comment: "Notes screen title"))
            .searchable(
                text: $searchText,
                prompt: NSLocalizedString("search_notes_placeholder", comment: "Search notes placeholder")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(viewModel.showFavoritesOnly ? .yellow : .primary)
                    }
                    .accessibilityLabel(
                        viewModel.showFavoritesOnly
                            ? NSLocalizedString("notes_show_all", comment: "Show all notes")
                            : NSLocalizedString("notes_favorites_filter", comment: "Show favorites only")
                    )
                    .accessibilityIdentifier("favorites_filter_button")
                }
            }
            .task {
                await viewModel.loadNotes()
            }
        }
    }
}

#Preview {
    ContentView(apiService: MockAPIService())
}
