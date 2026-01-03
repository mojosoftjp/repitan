import SwiftUI
import SwiftData

/// カード追加画面
struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var english = ""
    @State private var japanese = ""
    @State private var phonetic = ""
    @State private var example = ""
    @State private var exampleJapanese = ""
    @State private var addAnother = false

    private var canSave: Bool {
        !english.trimmingCharacters(in: .whitespaces).isEmpty &&
        !japanese.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("必須")) {
                    TextField("英単語", text: $english)
                        .font(.rpBody)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    TextField("日本語訳", text: $japanese)
                        .font(.rpBody)
                }

                Section(header: Text("オプション")) {
                    TextField("発音記号", text: $phonetic)
                        .font(.rpBody)
                        .autocapitalization(.none)

                    TextField("例文（英語）", text: $example, axis: .vertical)
                        .font(.rpBody)
                        .lineLimit(2...4)

                    TextField("例文（日本語）", text: $exampleJapanese, axis: .vertical)
                        .font(.rpBody)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("続けて追加", isOn: $addAnother)
                }
            }
            .navigationTitle("カードを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCard()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveCard() {
        let card = Card(
            japanese: japanese.trimmingCharacters(in: .whitespaces),
            english: english.trimmingCharacters(in: .whitespaces),
            phonetic: phonetic.isEmpty ? nil : phonetic.trimmingCharacters(in: .whitespaces),
            example: example.isEmpty ? nil : example.trimmingCharacters(in: .whitespaces),
            exampleJapanese: exampleJapanese.isEmpty ? nil : exampleJapanese.trimmingCharacters(in: .whitespaces),
            deck: deck
        )
        modelContext.insert(card)

        if addAnother {
            // フォームをリセット
            english = ""
            japanese = ""
            phonetic = ""
            example = ""
            exampleJapanese = ""
        } else {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)

    let deck = Deck(name: "テスト", categoryId: "custom")
    container.mainContext.insert(deck)

    return AddCardView(deck: deck)
        .modelContainer(container)
}
