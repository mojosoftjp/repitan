import Foundation
import SwiftData

/// 日次統計
/// 1日ごとの学習統計を記録し、ストリーク計算に使用
@Model
final class DailyStats {
    @Attribute(.unique) var id: UUID

    /// 対象日（時刻は00:00:00に正規化）
    @Attribute(.unique) var date: Date

    /// 新規学習カード数
    var newCardsCount: Int

    /// 復習カード数
    var reviewCardsCount: Int

    /// 正解数
    var correctCount: Int

    /// 総回答数
    var totalCount: Int

    /// 学習時間（秒）
    var studyTimeSeconds: Int

    /// その日時点の連続学習日数
    var currentStreak: Int

    // MARK: - Initialization

    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.newCardsCount = 0
        self.reviewCardsCount = 0
        self.correctCount = 0
        self.totalCount = 0
        self.studyTimeSeconds = 0
        self.currentStreak = 0
    }

    // MARK: - Computed Properties

    /// 正答率（0.0〜1.0）
    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    /// 正答率パーセント
    var accuracyPercent: Int {
        Int(accuracy * 100)
    }

    /// 学習時間（分）
    var studyTimeMinutes: Int {
        studyTimeSeconds / 60
    }

    /// 学習したカードの合計数
    var totalCardsStudied: Int {
        newCardsCount + reviewCardsCount
    }

    /// 学習を行ったかどうか（ストリーク判定用）
    var hasStudied: Bool {
        totalCardsStudied > 0
    }

    // MARK: - Methods

    /// 学習記録を追加
    /// - Parameters:
    ///   - isNew: 新規カードかどうか
    ///   - isCorrect: 正解かどうか
    func recordReview(isNew: Bool, isCorrect: Bool) {
        if isNew {
            newCardsCount += 1
        } else {
            reviewCardsCount += 1
        }
        totalCount += 1
        if isCorrect {
            correctCount += 1
        }
    }

    /// 学習時間を追加
    /// - Parameter seconds: 追加する秒数
    func addStudyTime(_ seconds: Int) {
        studyTimeSeconds += seconds
    }
}

// MARK: - DailyStats Helpers

extension DailyStats {
    /// 今日の日付で初期化されたDailyStatsを作成
    static func today() -> DailyStats {
        DailyStats(date: Date())
    }

    /// 指定した日付の開始時刻を取得
    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// 2つの日付が同じ日かどうかを判定
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}
