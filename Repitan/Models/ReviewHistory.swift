import Foundation
import SwiftData

/// 復習履歴
/// 各カードの復習記録を保持し、学習分析に使用
@Model
final class ReviewHistory {
    @Attribute(.unique) var id: UUID

    /// 復習日時
    var reviewedAt: Date

    /// 回答品質（SM-2スケール: 0-5）
    /// 0: 完全な失敗（Again）
    /// 1: 失敗だが覚えていた
    /// 2: 正解だが難しかった
    /// 3: 正解、適度な難易度（Hard）
    /// 4: 正解、簡単だった
    /// 5: 完璧（Easy）
    var quality: Int

    /// 回答時間（ミリ秒）
    var responseTimeMs: Int?

    /// 回答方法
    var answerMethod: AnswerMethod

    /// 復習時点でのinterval（日数）
    var intervalAtReview: Int?

    /// 復習時点でのeaseFactor
    var easeFactorAtReview: Double?

    // MARK: - Relationships

    var card: Card?
    var session: StudySession?

    // MARK: - Initialization

    init(
        quality: Int,
        answerMethod: AnswerMethod,
        responseTimeMs: Int? = nil,
        intervalAtReview: Int? = nil,
        easeFactorAtReview: Double? = nil
    ) {
        self.id = UUID()
        self.reviewedAt = Date()
        self.quality = min(5, max(0, quality))  // 0-5の範囲に制限
        self.answerMethod = answerMethod
        self.responseTimeMs = responseTimeMs
        self.intervalAtReview = intervalAtReview
        self.easeFactorAtReview = easeFactorAtReview
    }

    // MARK: - Computed Properties

    /// 正解かどうか（quality >= 3）
    var isCorrect: Bool {
        quality >= 3
    }

    /// 回答時間（秒）
    var responseTimeSeconds: Double? {
        guard let ms = responseTimeMs else { return nil }
        return Double(ms) / 1000.0
    }

    /// 評価の表示名
    var qualityDisplayName: String {
        switch quality {
        case 0: return "全然ダメ"
        case 1, 2: return "もう一回"
        case 3: return "少し考えた"
        case 4, 5: return "完璧！"
        default: return "不明"
        }
    }

    /// 評価のアイコン
    var qualityIcon: String {
        switch quality {
        case 0, 1, 2: return "😰"
        case 3: return "🤔"
        case 4, 5: return "😊"
        default: return "❓"
        }
    }
}

// MARK: - Quality Level

extension ReviewHistory {
    /// 3段階評価から品質値へのマッピング
    enum QualityLevel: Int, CaseIterable {
        case again = 0  // 全然ダメ
        case hard = 3   // 少し考えた
        case easy = 5   // 完璧！

        var displayName: String {
            switch self {
            case .again: return "全然ダメ"
            case .hard: return "少し考えた"
            case .easy: return "完璧！"
            }
        }

        var icon: String {
            switch self {
            case .again: return "😰"
            case .hard: return "🤔"
            case .easy: return "😊"
            }
        }

        var quality: Int {
            rawValue
        }
    }
}
