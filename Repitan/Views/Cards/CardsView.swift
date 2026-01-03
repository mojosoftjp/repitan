import SwiftUI
import SwiftData

/// カード管理画面（単語帳一覧）
struct CardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.sortOrder) private var decks: [Deck]

    @State private var showCreateDeck = false
    @State private var searchText = ""

    private var filteredDecks: [Deck] {
        if searchText.isEmpty {
            return decks
        }
        return decks.filter { deck in
            deck.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// 学年別単語帳（中1〜中3）
    private var gradeDecks: [Deck] {
        filteredDecks.filter { $0.categoryId.hasPrefix("junior_high_") }
    }

    /// 特別単語帳（不規則動詞など）
    private var specialDecks: [Deck] {
        filteredDecks.filter { $0.categoryId == "irregular_verbs" }
    }

    /// カスタム単語帳（ユーザー作成）
    private var customDecks: [Deck] {
        filteredDecks.filter {
            !$0.categoryId.hasPrefix("junior_high_") &&
            $0.categoryId != "irregular_verbs"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 検索バー
                    SearchBar(text: $searchText)
                        .padding(.horizontal)

                    // 学年別単語帳
                    if !gradeDecks.isEmpty {
                        DeckSection(title: "📚 学年別単語帳", decks: gradeDecks)
                    }

                    // 特別単語帳（不規則動詞など）
                    if !specialDecks.isEmpty {
                        DeckSection(title: "🔄 特別単語帳", decks: specialDecks)
                    }

                    // カスタム単語帳
                    DeckSection(
                        title: "📝 カスタム単語帳",
                        decks: customDecks,
                        showAddButton: true
                    ) {
                        showCreateDeck = true
                    }

                    // 単語帳がない場合
                    if decks.isEmpty {
                        EmptyDeckView {
                            showCreateDeck = true
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.rpBackground)
            .navigationTitle("カード管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateDeck) {
                CreateDeckView()
            }
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.rpTextSecondary)

            TextField("検索...", text: $text)
                .font(.rpBody)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.rpTextSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.rpCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Deck Section

struct DeckSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDecks: [Deck]

    let title: String
    let decks: [Deck]
    var showAddButton: Bool = false
    var onAddTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.rpTitle3)
                .foregroundColor(.rpTextPrimary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(decks) { deck in
                    NavigationLink {
                        DeckDetailView(deck: deck)
                    } label: {
                        DeckRow(deck: deck, onSelectTap: {
                            selectDeck(deck)
                        })
                    }
                    .buttonStyle(.plain)
                }

                if showAddButton {
                    Button {
                        onAddTap?()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.rpPrimary)

                            Text("新しい単語帳を作成")
                                .font(.rpBody)
                                .foregroundColor(.rpPrimary)

                            Spacer()
                        }
                        .padding()
                        .background(Color.rpCardBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    /// 単語帳を学習対象として選択
    private func selectDeck(_ deck: Deck) {
        // 他のすべての単語帳を非アクティブに
        for d in allDecks {
            d.isActive = false
        }
        // 選択した単語帳をアクティブに
        deck.isActive = true
        try? modelContext.save()
    }
}

// MARK: - Deck Row

struct DeckRow: View {
    let deck: Deck
    var onSelectTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // 選択ボタン（タップで学習単語帳を切り替え）
            Button {
                onSelectTap?()
            } label: {
                ZStack {
                    Text(deck.categoryIcon)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(deck.isActive ? Color.rpPrimary.opacity(0.2) : Color.rpPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // アクティブ時はチェックマーク
                    if deck.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.rpPrimary)
                            .background(Color.white.clipShape(Circle()))
                            .offset(x: 16, y: 16)
                    }
                }
            }
            .buttonStyle(.plain)

            // 単語帳情報
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(deck.name)
                        .font(.rpBodyBold)
                        .foregroundColor(.rpTextPrimary)

                    // アクティブバッジ
                    if deck.isActive {
                        Text("学習中")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.rpPrimary)
                            .cornerRadius(4)
                    }
                }

                Text("\(deck.totalCardCount)語 / 完了: \(deck.masteredCardCount)語")
                    .font(.rpCaption1)
                    .foregroundColor(.rpTextSecondary)
            }

            Spacer()

            // 進捗インジケータ
            if deck.totalCardCount > 0 {
                CircularProgressView(progress: deck.progress)
            }

            Image(systemName: "chevron.right")
                .font(.rpCaption1)
                .foregroundColor(.rpTextSecondary)
        }
        .padding()
        .background(deck.isActive ? Color.rpPrimary.opacity(0.05) : Color.rpCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(deck.isActive ? Color.rpPrimary : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rpTextSecondary.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.rpSuccess, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Empty Deck View

struct EmptyDeckView: View {
    let onCreateTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.rpTextSecondary)

            Text("単語帳がありません")
                .font(.rpTitle3)
                .foregroundColor(.rpTextPrimary)

            Text("単語帳を作成して\n単語を追加しましょう")
                .font(.rpBody)
                .foregroundColor(.rpTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                onCreateTap()
            } label: {
                Text("単語帳を作成")
            }
            .buttonStyle(RPPrimaryButtonStyle())
            .frame(width: 200)
        }
        .padding(32)
        .rpCardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    CardsView()
        .modelContainer(for: [
            Deck.self,
            Card.self,
        ], inMemory: true)
}
