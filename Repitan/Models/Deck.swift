import Foundation
import SwiftData

/// 活用形出題モード
/// 単語帳ごとに設定し、学習時にどの活用形を要求するか決定
enum ConjugationMode: Int, Codable, CaseIterable {
    case presentOnly = 0      // 現在形のみ（デフォルト）
    case presentAndPast = 1   // 現在形＋過去形
    case allForms = 2         // 現在形＋過去形＋過去分詞

    var displayName: String {
        switch self {
        case .presentOnly: return "現在形のみ"
        case .presentAndPast: return "現在形＋過去形"
        case .allForms: return "現在形＋過去形＋過去分詞"
        }
    }

    var description: String {
        switch self {
        case .presentOnly: return "基本形のみを出題"
        case .presentAndPast: return "基本形と過去形の両方を出題"
        case .allForms: return "基本形・過去形・過去分詞すべてを出題"
        }
    }
}

/// 単語帳（単語帳）
/// 複数のカードをグループ化して管理するためのコンテナ
@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var deckDescription: String
    var iconName: String
    var categoryId: String
    var isBuiltIn: Bool
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    /// 組み込み単語帳のバージョン（アップデート検知用）
    var builtInVersion: String?

    /// 活用形出題モード（現在形のみ / 現在形＋過去形 / 全活用形）
    var conjugationModeRaw: Int

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]

    /// 活用形出題モード（computed property）
    var conjugationMode: ConjugationMode {
        get { ConjugationMode(rawValue: conjugationModeRaw) ?? .presentOnly }
        set { conjugationModeRaw = newValue.rawValue }
    }

    init(
        name: String,
        categoryId: String = "custom",
        deckDescription: String = "",
        iconName: String = "rectangle.stack",
        isBuiltIn: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.deckDescription = deckDescription
        self.iconName = iconName
        self.categoryId = categoryId
        self.isBuiltIn = isBuiltIn
        self.isActive = true
        self.sortOrder = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.cards = []
        self.conjugationModeRaw = ConjugationMode.presentOnly.rawValue
    }

    // MARK: - Computed Properties

    /// カテゴリの表示名
    var categoryDisplayName: String {
        DeckCategoryManager.displayName(for: categoryId)
    }

    /// カテゴリのアイコン
    var categoryIcon: String {
        DeckCategoryManager.icon(for: categoryId)
    }

    /// 総カード数
    var totalCardCount: Int {
        cards.count
    }

    /// 新規（未学習）カード数
    var newCardCount: Int {
        cards.filter { $0.status == .new }.count
    }

    /// 学習中カード数（learningまたはrelearning）
    var learningCardCount: Int {
        cards.filter { $0.status == .learning || $0.status == .relearning }.count
    }

    /// 復習待ちカード数
    var reviewCardCount: Int {
        cards.filter { $0.status == .review }.count
    }

    /// 習得済みカード数
    var masteredCardCount: Int {
        cards.filter { $0.status == .mastered }.count
    }

    /// 今日復習が必要なカード
    var cardsDueToday: [Card] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return cards.filter { card in
            card.status == .review && card.nextReviewDate < tomorrow
        }
    }

    /// 学習進捗（0.0〜1.0）
    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        let completedCount = cards.filter { $0.status == .review || $0.status == .mastered }.count
        return Double(completedCount) / Double(cards.count)
    }
}
