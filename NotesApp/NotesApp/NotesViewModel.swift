import Foundation

final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
}
