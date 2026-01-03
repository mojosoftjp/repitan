import SwiftUI
import SwiftData

/// ホーム画面（ダッシュボード）
/// 学習状況のサマリーと学習開始ボタンを表示
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [Card]
    @Query private var allDecks: [Deck]
    @Query(sort: \DailyStats.date, order: .reverse) private var recentStats: [DailyStats]
    @Query private var settings: [UserSettings]

    @State private var showStudySession = false
    @State private var showDirectReview = false
    @State private var reviewCardsToStudy: [Card] = []
    @State private var currentStreak: Int = 0
    @State private var todayStats: DailyStatsSummary = .empty

    private var userSettings: UserSettings? {
        settings.first
    }

    private var reviewDueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return allCards.filter { card in
            (card.status == .review || card.status == .mastered) && card.nextReviewDate < tomorrow
        }.count
    }

    private var newCardsAvailable: Int {
        allCards.filter { $0.status == .new }.count
    }

    private var learningCardsCount: Int {
        allCards.filter { $0.status == .learning || $0.status == .relearning }.count
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

    /// 復習対象カード（review/masteredステータスのみ）
    private var reviewDueCards: [Card] {
        let today = Calendar.current.startOfDay(for: Date())
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

    /// 学習中カード（learning/relearningステータス）- 今すぐ復習可能なもののみ
    private var learningCards: [Card] {
        activeCards.filter { $0.status == .learning || $0.status == .relearning }
            .filter { card in
                guard let dueDate = card.learningDueDate else { return true }
                return dueDate <= Date()
            }
    }

    /// 待機中の学習カード（learningDueDateがまだ来ていないもの）
    private var pendingLearningCards: [Card] {
        activeCards.filter { $0.status == .learning || $0.status == .relearning }
            .filter { card in
                guard let dueDate = card.learningDueDate else { return false }
                return dueDate > Date()
            }
    }

    /// 今すぐ復習可能なカード数（待機中を除く）
    private var reviewReadyCount: Int {
        reviewDueCards.count + learningCards.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ストリークカード
                    StreakCard(streak: currentStreak, hasStudiedToday: todayStats.hasStudiedToday)

                    // 今日の学習状況
                    TodayProgressCard(
                        newCardsStudied: todayStats.newCardsStudied,
                        reviewCardsStudied: todayStats.reviewCardsStudied,
                        dailyGoal: userSettings?.dailyNewCardGoal ?? 10
                    )

                    // 復習待ちカード
                    if reviewDueCount > 0 || learningCardsCount > 0 {
                        DueCardsCard(
                            reviewDueCount: reviewDueCount,
                            learningCount: learningCardsCount
                        )
                    }

                    // 学習開始ボタン
                    VStack(spacing: 12) {
                        // 復習可能なカードがある場合のみ表示（待機中は除く）
                        if reviewReadyCount > 0 {
                            Button {
                                prepareReviewCards()
                                showDirectReview = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("復習を始める")
                                }
                            }
                            .buttonStyle(RPPrimaryButtonStyle())
                        }

                        if newCardsAvailable > 0 {
                            Button {
                                showStudySession = true
                            } label: {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("新しい単語を覚える")
                                }
                            }
                            .buttonStyle(RPSecondaryButtonStyle())
                        }

                        if allDecks.isEmpty || allCards.isEmpty {
                            EmptyStateCard()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.rpBackground)
            .navigationTitle("リピたん")
            .onAppear {
                loadStats()
            }
            .sheet(isPresented: $showStudySession, onDismiss: {
                // 学習セッション終了後に統計を再読み込み
                loadStats()
            }) {
                StudySessionView()
            }
            .fullScreenCover(isPresented: $showDirectReview, onDismiss: {
                // 復習セッション終了後に統計を再読み込み
                loadStats()
            }) {
                TestView(cards: reviewCardsToStudy, sessionType: .review)
            }
        }
    }

    /// 復習用カードを準備（復習可能なカードのみ、待機中は含まない）
    private func prepareReviewCards() {
        let reviewLimit = userSettings?.dailyReviewLimit ?? 50

        // 学習中カード優先、その後復習カード（重複を除去）
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

        reviewCardsToStudy = cards
    }

    private func loadStats() {
        let statsManager = DailyStatsManager(modelContext: modelContext)
        todayStats = statsManager.getTodaySummary()
        currentStreak = todayStats.currentStreak

        // 翌日の復習通知を更新
        updateDailySummaryNotification()
    }

    /// 毎日の復習通知を更新（復習件数を反映）
    private func updateDailySummaryNotification() {
        // 通知が有効な場合のみ
        guard userSettings?.notificationEnabled ?? false else { return }

        // 翌日の朝9時時点で期限になるカード数を計算
        let calendar = Calendar.current
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        tomorrowComponents.day! += 1
        tomorrowComponents.hour = 9
        tomorrowComponents.minute = 0
        let tomorrowMorning = calendar.date(from: tomorrowComponents)!

        // 翌日朝9時までに復習期限が来るreview/masteredカードをカウント
        let tomorrowReviewCount = allCards.filter { card in
            (card.status == .review || card.status == .mastered) && card.nextReviewDate <= tomorrowMorning
        }.count

        // 通知を更新
        NotificationManager.shared.scheduleDailySummaryNotification(reviewCount: tomorrowReviewCount)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int
    let hasStudiedToday: Bool

    /// 吹き出しの背景色（薄いオレンジ）
    private let bubbleColor = Color.rpStreak.opacity(0.15)

    var body: some View {
        HStack(spacing: 6) {
            // キャラクター画像（テキストなし版）
            Image("RepitanCharacter")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)

            // 吹き出し
            SpeechBubble(color: bubbleColor) {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak)日連続")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.rpStreak)

                        Text(hasStudiedToday ? "今日も学習完了！" : "今日も学習しよう！")
                            .font(.rpCaption1)
                            .foregroundColor(.rpTextSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .rpCardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Speech Bubble

struct SpeechBubble<Content: View>: View {
    let color: Color
    let content: Content

    init(color: Color = Color.rpCardBackground, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: -1) {
            // 吹き出しの三角形（左向き）
            BubbleTail()
                .fill(color)
                .frame(width: 10, height: 14)

            // 吹き出し本体
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(color)
                .cornerRadius(14)
        }
    }
}

// MARK: - Bubble Tail Shape

/// 吹き出しの尻尾（左向きの三角形）
struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 右上から開始
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2))
        // 左中央へ
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        // 右下へ
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.2))
        path.closeSubpath()
        return path
    }
}

// MARK: - Today Progress Card

struct TodayProgressCard: View {
    let newCardsStudied: Int
    let reviewCardsStudied: Int
    let dailyGoal: Int

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(newCardsStudied) / Double(dailyGoal))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日の学習")
                .font(.rpTitle3)
                .foregroundColor(.rpTextPrimary)

            HStack(spacing: 24) {
                StatItem(
                    value: "\(newCardsStudied)",
                    label: "新規",
                    icon: "book.fill",
                    color: .rpPrimary
                )

                StatItem(
                    value: "\(reviewCardsStudied)",
                    label: "復習",
                    icon: "arrow.clockwise",
                    color: .rpSecondary
                )
            }

            // 進捗バー
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.rpTextSecondary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.rpPrimary)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("目標: \(newCardsStudied)/\(dailyGoal)語")
                    .font(.rpCaption1)
                    .foregroundColor(.rpTextSecondary)
            }
        }
        .padding()
        .rpCardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.rpTitle3)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.rpStatsNumber)
                    .foregroundColor(.rpTextPrimary)

                Text(label)
                    .font(.rpCaption1)
                    .foregroundColor(.rpTextSecondary)
            }
        }
    }
}

// MARK: - Due Cards Card

struct DueCardsCard: View {
    let reviewDueCount: Int
    let learningCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学習待ち")
                .font(.rpTitle3)
                .foregroundColor(.rpTextPrimary)

            HStack(spacing: 16) {
                if reviewDueCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.rpWarning)
                        Text("復習: \(reviewDueCount)語")
                            .font(.rpBody)
                            .foregroundColor(.rpTextPrimary)
                    }
                }

                if learningCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.rpSecondary)
                        Text("学習中: \(learningCount)語")
                            .font(.rpBody)
                            .foregroundColor(.rpTextPrimary)
                    }
                }
            }
        }
        .padding()
        .rpCardStyle()
        .padding(.horizontal)
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.rpTextSecondary)

            Text("単語帳がありません")
                .font(.rpTitle3)
                .foregroundColor(.rpTextPrimary)

            Text("カードタブから単語帳を追加して\n学習を始めましょう！")
                .font(.rpBody)
                .foregroundColor(.rpTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .rpCardStyle()
    }
}

// MARK: - Preview

#Preview {
    HomeView()
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
