import SwiftUI

struct CharacterCounter: View {
    let count: Int

    var body: some View {
        Text(String(format: NSLocalizedString("character_count", comment: ""), count))
            .font(.caption)
            .foregroundColor(.gray)
            .accessibilityLabel(String(format: NSLocalizedString("character_count", comment: ""), count))
    }
}

#Preview {
    CharacterCounter(count: 42)
}
