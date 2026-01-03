import SwiftUI
import SwiftData

/// 学習セッション選択画面
struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCards: [Card]
    @Query private var allDecks: [Deck]
    @Query private var settings: [UserSettings]

    @State private var selectedSessionType: SessionType = .mixed
    @State private var showTestView = false
    @State private var cardsToStudy: [Card] = []
    @State private var currentTime = Date()

    private var userSettings: UserSettings? {
        settings.first
    }

    /// アクティブな単語帳
    private var activeDeck: Deck? {
        allDecks.first { $0.isActive }
    }

    /// アクティブな単語帳のカードのみ
    private var activeCards: [Card] {
        guard let deck = activeDeck else { return [] }
        return deck.cards
    }

    /// 復習対象カード（review/masteredステータスのみ、learning/relearningは含まない）
    private var reviewDueCards: [Card] {
        let today = Calendar.current.startOfDay(for: currentTime)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return activeCards.filter { card in
            switch card.status {
            case .review, .mastered:
                return card.nextReviewDate < tomorrow
            case .learning, .relearning, .new:
                return false
            }
        }
    }

    private var newCards: [Card] {
        activeCards.filter { $0.status == .new }
    }

    /// 学習中カード（learning/relearningステータス）- 今すぐ復習可能なもののみ
    private var learningCards: [Card] {
        activeCards.filter { $0.status == .learning || $0.status == .relearning }
            .filter { card in
                guard let dueDate = card.learningDueDate else { return true }
                return dueDate <= currentTime
            }
    }

    /// 待機中の学習カード（learningDueDateがまだ来ていないもの）
    private var pendingLearningCards: [Card] {
        activeCards.filter { $0.status == .learning || $0.status == .relearning }
            .filter { card in
                guard let dueDate = card.learningDueDate else { return false }
                return dueDate > currentTime
            }
    }

    /// 復習モードで表示するカード数（今すぐ復習可能なもののみ、待機中は含まない）
    private var reviewReadyCount: Int {
        reviewDueCards.count + learningCards.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("学習モードを選択")
                    .font(.rpTitle2)
                    .foregroundColor(.rpTextPrimary)
                    .padding(.top)

                // 選択中の単語帳表示
                if let deck = activeDeck {
                    HStack {
                        Text(deck.categoryIcon)
                            .font(.system(size: 20))
                        Text(deck.name)
                            .font(.rpBodyBold)
                            .foregroundColor(.rpTextPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.rpPrimary.opacity(0.1))
                    .cornerRadius(8)
                }

                VStack(spacing: 16) {
                    // 復習モード
                    SessionTypeCard(
                        type: .review,
                        isSelected: selectedSessionType == .review,
                        cardCount: reviewReadyCount,
                        pendingCount: pendingLearningCards.count
                    ) {
                        selectedSessionType = .review
                    }

                    // 新規学習モード（単語帳名を表示）
                    SessionTypeCard(
                        type: .newLearning,
                        isSelected: selectedSessionType == .newLearning,
                        cardCount: newCards.count,
                        customTitle: activeDeck?.name
                    ) {
                        selectedSessionType = .newLearning
                    }

                    // おまかせモード
                    SessionTypeCard(
                        type: .mixed,
                        isSelected: selectedSessionType == .mixed,
                        cardCount: reviewReadyCount + min(newCards.count, userSettings?.dailyNewCardGoal ?? 10),
                        pendingCount: pendingLearningCards.count
                    ) {
                        selectedSessionType = .mixed
                    }
                }
                .padding(.horizontal)

                Spacer()

                // 学習開始ボタン
                Button {
                    prepareCards()
                    if !cardsToStudy.isEmpty {
                        showTestView = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("学習を始める")
                    }
                }
                .buttonStyle(RPPrimaryButtonStyle(isEnabled: canStartStudy))
                .disabled(!canStartStudy)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.rpBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showTestView) {
                TestView(cards: cardsToStudy, sessionType: selectedSessionType)
            }
            .onAppear {
                // 画面表示時に現在時刻を更新
                currentTime = Date()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // アプリがフォアグラウンドになったときに現在時刻を更新
                currentTime = Date()
            }
            .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
                // 10秒ごとに現在時刻を更新（待機中カードの時刻チェック用）
                currentTime = Date()
            }
        }
    }

    private var canStartStudy: Bool {
        switch selectedSessionType {
        case .review:
            // 復習モードは復習可能なカードのみ（待機中は除外）
            return !reviewDueCards.isEmpty || !learningCards.isEmpty
        case .newLearning:
            return !newCards.isEmpty
        case .mixed:
            // おまかせモードは待機中も含む
            return !reviewDueCards.isEmpty || !learningCards.isEmpty || !pendingLearningCards.isEmpty || !newCards.isEmpty
        }
    }

    private func prepareCards() {
        let dailyGoal = userSettings?.dailyNewCardGoal ?? 10
        let reviewLimit = userSettings?.dailyReviewLimit ?? 50

        // 待機中カードをlearningDueDate順にソート
        let sortedPendingCards = pendingLearningCards.sorted { a, b in
            (a.learningDueDate ?? Date()) < (b.learningDueDate ?? Date())
        }

        switch selectedSessionType {
        case .review:
            // 学習中カード優先、その後復習カード（重複を除去）
            // 待機中カードは含めない
            var cards: [Card] = []
            var usedIds = Set<UUID>()

            for card in learningCards.prefix(reviewLimit) {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            for card in reviewDueCards.prefix(reviewLimit - cards.count) {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            cardsToStudy = cards

        case .newLearning:
            // 新規カードのみ
            cardsToStudy = Array(newCards.prefix(dailyGoal))

        case .mixed:
            // 学習中 → 復習 → 待機中 → 新規 の順（重複を除去）
            var cards: [Card] = []
            var usedIds = Set<UUID>()

            for card in learningCards {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            for card in reviewDueCards.prefix(reviewLimit) {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            // 待機中カードも追加
            for card in sortedPendingCards {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            for card in newCards.prefix(dailyGoal) {
                if !usedIds.contains(card.id) {
                    cards.append(card)
                    usedIds.insert(card.id)
                }
            }

            cardsToStudy = cards
        }
    }
}

// MARK: - Session Type Card

struct SessionTypeCard: View {
    let type: SessionType
    let isSelected: Bool
    let cardCount: Int
    var customTitle: String? = nil
    var pendingCount: Int = 0
    let onTap: () -> Void

    /// 表示するタイトル（カスタムタイトルがあればそれを使用）
    private var displayTitle: String {
        if type == .newLearning, let custom = customTitle {
            return custom
        }
        return type.displayName
    }

    /// 表示する説明
    private var displayDescription: String {
        if type == .newLearning, customTitle != nil {
            return "新規カードを学習"
        }
        if pendingCount > 0 {
            return "\(pendingCount)語が待機中"
        }
        return type.description
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: type.iconName)
                    .font(.rpTitle2)
                    .foregroundColor(isSelected ? .white : .rpPrimary)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? Color.rpPrimary : Color.rpPrimary.opacity(0.1))
                    .clipShape(Circle())

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle)
                        .font(.rpBodyBold)
                        .foregroundColor(.rpTextPrimary)

                    Text(displayDescription)
                        .font(.rpCaption1)
                        .foregroundColor(pendingCount > 0 ? .rpWarning : .rpTextSecondary)
                }

                Spacer()

                // カード数
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(cardCount)")
                        .font(.rpStatsNumber)
                        .foregroundColor(.rpPrimary)

                    Text("語")
                        .font(.rpCaption1)
                        .foregroundColor(.rpTextSecondary)
                }
            }
            .padding()
            .background(Color.rpCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.rpPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    StudySessionView()
        .modelContainer(for: [
            Deck.self,
            Card.self,
            ReviewHistory.self,
            StudySession.self,
            DailyStats.self,
            UserSettings.self,
            Achievement.self,
        ], inMemory: true)
}
