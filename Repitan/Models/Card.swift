import Foundation
import SwiftData

/// 単語カード
/// SM-2アルゴリズムによる間隔反復学習のパラメータを保持
@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var japanese: String
    var english: String
    var phonetic: String?
    var example: String?
    var exampleJapanese: String?
    var audioURL: String?
    var imageURL: String?

    // MARK: - Part of Speech

    /// 品詞（名詞、動詞、形容詞など）
    var partOfSpeech: String?

    // MARK: - Irregular Verb Forms (Optional)

    /// 過去形（不規則動詞用）例: ran, went, ate
    var pastTense: String?

    /// 過去分詞（不規則動詞用）例: run, gone, eaten
    var pastParticiple: String?

    /// 過去形の発音記号
    var pastTensePhonetic: String?

    /// 過去分詞の発音記号
    var pastParticiplePhonetic: String?

    // MARK: - SM-2 Algorithm Parameters

    /// 難易度係数（Ease Factor）
    /// 初期値: 2.5、最小値: 1.3
    /// 高いほど簡単なカード
    var easeFactor: Double

    /// 次回復習までの日数（interval）
    /// 0: まだ学習していない、1以上: 日数
    var interval: Int

    /// 連続正解回数
    var repetitions: Int

    /// 次回復習日
    var nextReviewDate: Date

    /// 忘れた回数（ラプス）
    /// Again評価でリセットされた回数
    var lapses: Int

    // MARK: - Learning Step Management

    /// 学習ステップ
    /// 0: 未学習（new）
    /// 1〜n: 学習中（learning/relearning）のステップ番号
    /// -1: 卒業済み（review/mastered）
    var learningStep: Int

    /// 学習中の次回表示時刻
    /// learningまたはrelearning状態のカードで使用
    var learningDueDate: Date?

    /// 学習状態
    var status: CardStatus

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships

    var deck: Deck?

    @Relationship(deleteRule: .cascade, inverse: \ReviewHistory.card)
    var reviewHistories: [ReviewHistory]

    // MARK: - Initialization

    init(
        japanese: String,
        english: String,
        phonetic: String? = nil,
        example: String? = nil,
        exampleJapanese: String? = nil,
        audioURL: String? = nil,
        imageURL: String? = nil,
        partOfSpeech: String? = nil,
        pastTense: String? = nil,
        pastParticiple: String? = nil,
        pastTensePhonetic: String? = nil,
        pastParticiplePhonetic: String? = nil,
        deck: Deck? = nil
    ) {
        self.id = UUID()
        self.japanese = japanese
        self.english = english
        self.phonetic = phonetic
        self.example = example
        self.exampleJapanese = exampleJapanese
        self.audioURL = audioURL
        self.imageURL = imageURL
        self.partOfSpeech = partOfSpeech
        self.pastTense = pastTense
        self.pastParticiple = pastParticiple
        self.pastTensePhonetic = pastTensePhonetic
        self.pastParticiplePhonetic = pastParticiplePhonetic
        self.easeFactor = 2.5
        self.interval = 0
        self.repetitions = 0
        self.nextReviewDate = Date()
        self.lapses = 0
        self.learningStep = 0
        self.status = .new
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deck = deck
        self.reviewHistories = []
    }

    // MARK: - Computed Properties

    /// カードが今すぐ復習可能かどうか
    var isDue: Bool {
        switch status {
        case .new:
            return true
        case .learning, .relearning:
            guard let dueDate = learningDueDate else { return true }
            return Date() >= dueDate
        case .review, .mastered:
            return Date() >= Calendar.current.startOfDay(for: nextReviewDate)
        }
    }

    /// 最後の復習からの経過日数
    var daysSinceLastReview: Int? {
        guard let lastReview = reviewHistories.max(by: { $0.reviewedAt < $1.reviewedAt }) else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: lastReview.reviewedAt, to: Date()).day
    }

    /// 復習回数の合計
    var totalReviewCount: Int {
        reviewHistories.count
    }

    /// 習得率（正解率）
    var accuracy: Double {
        guard !reviewHistories.isEmpty else { return 0 }
        let correctCount = reviewHistories.filter { $0.quality >= 3 }.count
        return Double(correctCount) / Double(reviewHistories.count)
    }

    /// 不規則動詞かどうか（過去形または過去分詞が設定されている）
    var hasIrregularForms: Bool {
        pastTense != nil || pastParticiple != nil
    }
}

// MARK: - Card Sorting

extension Card {
    /// 復習優先度でソート用のスコアを計算
    /// 低いほど優先度が高い
    var priorityScore: Double {
        switch status {
        case .new:
            return 100.0
        case .learning, .relearning:
            guard let dueDate = learningDueDate else { return 0 }
            return dueDate.timeIntervalSinceNow / 60.0 // 分単位
        case .review, .mastered:
            return nextReviewDate.timeIntervalSinceNow / 3600.0 / 24.0 // 日単位
        }
    }
}
