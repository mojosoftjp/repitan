import SwiftUI
import SwiftData

/// 単語帳作成画面
struct CreateDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var deckName = ""
    @State private var deckDescription = ""

    private var canSave: Bool {
        !deckName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("単語帳名", text: $deckName)
                        .font(.rpBody)

                    TextField("説明（任意）", text: $deckDescription, axis: .vertical)
                        .font(.rpBody)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新しい単語帳")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDeck()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveDeck() {
        let deck = Deck(
            name: deckName.trimmingCharacters(in: .whitespaces),
            categoryId: "custom",
            deckDescription: deckDescription
        )
        // 新規作成時は自動選択しない（ユーザーに選択を任せる）
        deck.isActive = false
        modelContext.insert(deck)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    CreateDeckView()
        .modelContainer(for: Deck.self, inMemory: true)
}
