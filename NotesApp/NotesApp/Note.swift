import Foundation

struct Note: Identifiable {
    let id: UUID
    let text: String
    var isFavorited: Bool

    init(text: String, isFavorited: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isFavorited = isFavorited
    }
}
