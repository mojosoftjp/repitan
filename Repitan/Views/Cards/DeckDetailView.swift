import SwiftUI
import SwiftData

/// 単語帳詳細画面
struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var deck: Deck

    @Environment(\.dismiss) private var dismiss

    @State private var showAddCard = false
    @State private var showCSVImport = false
    @State private var showDeckSettings = false
    @State private var showDeleteConfirmation = false
    @State private var searchText = ""
    @State private var selectedFilter: CardFilter = .all

    enum CardFilter: String, CaseIterable {
        case all = "すべて"
        case new = "未学習"
        case learning = "学習中"
        case review = "復習待ち"
        case mastered = "習得済み"

        func matches(_ card: Card) -> Bool {
            switch self {
            case .all: return true
            case .new: return card.status == .new
            case .learning: return card.status == .learning || card.status == .relearning
            case .review: return card.status == .review
            case .mastered: return card.status == .mastered
            }
        }
    }

    private var filteredCards: [Card] {
        var cards = deck.cards.filter { selectedFilter.matches($0) }

        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.japanese.localizedCaseInsensitiveContains(searchText) ||
                card.english.localizedCaseInsensitiveContains(searchText)
            }
        }

        return cards.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 統計サマリー
            DeckStatsHeader(deck: deck)

            // フィルター
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CardFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // 検索バー
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.bottom, 8)

            // カードリスト
            List {
                ForEach(filteredCards) { card in
                    CardRow(card: card)
                }
                .onDelete(perform: deleteCards)
            }
            .listStyle(.plain)
        }
        .background(Color.rpBackground)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showAddCard = true
                    } label: {
                        Label("カードを追加", systemImage: "plus")
                    }

                    Button {
                        showCSVImport = true
                    } label: {
                        Label("CSVインポート", systemImage: "doc.text")
                    }

                    Divider()

                    Button {
                        showDeckSettings = true
                    } label: {
                        Label("単語帳設定", systemImage: "gearshape")
                    }

                    // ビルトイン単語帳は削除不可
                    if !deck.isBuiltIn {
                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("単語帳を削除", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardView(deck: deck)
        }
        .sheet(isPresented: $showCSVImport) {
            CSVImportView(deck: deck)
        }
        .sheet(isPresented: $showDeckSettings) {
            DeckSettingsView(deck: deck)
        }
        .alert("単語帳を削除", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                deleteDeck()
            }
        } message: {
            Text("「\(deck.name)」を削除しますか？\n\(deck.totalCardCount)語のカードもすべて削除されます。この操作は取り消せません。")
        }
    }

    /// 単語帳を削除
    private func deleteDeck() {
        modelContext.delete(deck)
        dismiss()
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            let card = filteredCards[index]
            modelContext.delete(card)
        }
    }
}

// MARK: - Deck Stats Header

struct DeckStatsHeader: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 16) {
            StatPill(count: deck.newCardCount, label: "未学習", color: .rpTextSecondary)
            StatPill(count: deck.learningCardCount, label: "学習中", color: .rpSecondary)
            StatPill(count: deck.reviewCardCount, label: "復習", color: .rpWarning)
            StatPill(count: deck.masteredCardCount, label: "習得", color: .rpSuccess)
        }
        .padding()
        .background(Color.rpCardBackground)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.rpBodyBold)
                .foregroundColor(color)

            Text(label)
                .font(.rpCaption2)
                .foregroundColor(.rpTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.rpCaption1)
                .foregroundColor(isSelected ? .white : .rpTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.rpPrimary : Color.rpCardBackground)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Row

struct CardRow: View {
    let card: Card

    private var statusColor: Color {
        switch card.status {
        case .new: return .rpTextSecondary
        case .learning, .relearning: return .rpSecondary
        case .review: return .rpWarning
        case .mastered: return .rpSuccess
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // ステータスインジケータ
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.english)
                    .font(.rpBodyBold)
                    .foregroundColor(.rpTextPrimary)

                Text(card.japanese)
                    .font(.rpSubheadline)
                    .foregroundColor(.rpTextSecondary)
            }

            Spacer()

            // 次回復習
            if card.status != .new {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("次回")
                        .font(.rpCaption2)
                        .foregroundColor(.rpTextSecondary)

                    Text(formatNextReview(card.nextReviewDate))
                        .font(.rpCaption1)
                        .foregroundColor(.rpTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatNextReview(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let reviewDay = calendar.startOfDay(for: date)

        let days = calendar.dateComponents([.day], from: today, to: reviewDay).day ?? 0

        if days <= 0 {
            return "今日"
        } else if days == 1 {
            return "明日"
        } else {
            return "\(days)日後"
        }
    }
}

// MARK: - Deck Settings View

/// 単語帳設定画面
struct DeckSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var deck: Deck

    /// 過去形を持つカードがあるか
    private var hasCardsWithPastTense: Bool {
        deck.cards.contains { $0.pastTense != nil }
    }

    /// 過去分詞を持つカードがあるか
    private var hasCardsWithPastParticiple: Bool {
        deck.cards.contains { $0.pastParticiple != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                // 活用形出題モード
                Section {
                    ForEach(ConjugationMode.allCases, id: \.self) { mode in
                        Button {
                            deck.conjugationMode = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.rpBody)
                                        .foregroundColor(isAvailable(mode) ? .rpTextPrimary : .rpTextSecondary)

                                    Text(mode.description)
                                        .font(.rpCaption)
                                        .foregroundColor(.rpTextSecondary)
                                }

                                Spacer()

                                if deck.conjugationMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.rpPrimary)
                                }
                            }
                        }
                        .disabled(!isAvailable(mode))
                    }
                } header: {
                    Text("出題モード")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        if !hasCardsWithPastTense {
                            Label("過去形のあるカードがありません", systemImage: "info.circle")
                                .font(.rpCaption)
                                .foregroundColor(.rpTextSecondary)
                        }
                        if !hasCardsWithPastParticiple && hasCardsWithPastTense {
                            Label("過去分詞のあるカードがありません", systemImage: "info.circle")
                                .font(.rpCaption)
                                .foregroundColor(.rpTextSecondary)
                        }

                        Text("「現在形＋過去形」や「全活用形」を選択すると、過去形・過去分詞を持つカードは両方の活用形を正解しないと復習済みになりません。")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                    }
                }

                // 統計情報
                Section {
                    HStack {
                        Text("過去形を持つカード")
                        Spacer()
                        Text("\(deck.cards.filter { $0.pastTense != nil }.count)語")
                            .foregroundColor(.rpTextSecondary)
                    }

                    HStack {
                        Text("過去分詞を持つカード")
                        Spacer()
                        Text("\(deck.cards.filter { $0.pastParticiple != nil }.count)語")
                            .foregroundColor(.rpTextSecondary)
                    }
                } header: {
                    Text("カード情報")
                }
            }
            .navigationTitle("単語帳設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// モードが利用可能かチェック
    private func isAvailable(_ mode: ConjugationMode) -> Bool {
        switch mode {
        case .presentOnly:
            return true
        case .presentAndPast:
            return hasCardsWithPastTense
        case .allForms:
            return hasCardsWithPastTense && hasCardsWithPastParticiple
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)

    let deck = Deck(name: "テスト単語帳", categoryId: "custom")
    container.mainContext.insert(deck)

    let card1 = Card(japanese: "重要な", english: "important")
    card1.deck = deck
    container.mainContext.insert(card1)

    return NavigationStack {
        DeckDetailView(deck: deck)
    }
    .modelContainer(container)
}
