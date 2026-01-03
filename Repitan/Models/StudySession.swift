import Foundation
import SwiftData

/// 学習セッション
/// 1回の学習セッションの記録を保持
@Model
final class StudySession {
    @Attribute(.unique) var id: UUID

    /// セッション開始日時
    var startedAt: Date

    /// セッション完了日時
    var completedAt: Date?

    /// セッションタイプ
    var sessionType: SessionType

    /// 学習したカード数
    var cardsStudied: Int

    /// 正解数
    var correctCount: Int

    /// 学習時間（秒）
    var durationSeconds: Int

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \ReviewHistory.session)
    var reviewHistories: [ReviewHistory]

    // MARK: - Initialization

    init(sessionType: SessionType) {
        self.id = UUID()
        self.startedAt = Date()
        self.sessionType = sessionType
        self.cardsStudied = 0
        self.correctCount = 0
        self.durationSeconds = 0
        self.reviewHistories = []
    }

    // MARK: - Computed Properties

    /// セッションが完了しているか
    var isCompleted: Bool {
        completedAt != nil
    }

    /// 正答率
    var accuracy: Double {
        guard cardsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(cardsStudied)
    }

    /// 正答率パーセント（表示用）
    var accuracyPercent: Int {
        Int(accuracy * 100)
    }

    /// 学習時間（分）
    var durationMinutes: Int {
        durationSeconds / 60
    }

    /// 学習時間のフォーマット済み文字列
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }

    // MARK: - Methods

    /// セッションを完了する
    func complete() {
        completedAt = Date()
        if let start = Optional(startedAt) {
            durationSeconds = Int(Date().timeIntervalSince(start))
        }
    }

    /// カード学習結果を記録
    /// - Parameters:
    ///   - isCorrect: 正解かどうか
    func recordAnswer(isCorrect: Bool) {
        cardsStudied += 1
        if isCorrect {
            correctCount += 1
        }
    }
}
