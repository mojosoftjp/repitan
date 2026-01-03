import Foundation
import SwiftData

/// 日次統計管理サービス
@MainActor
class DailyStatsManager {

    private let modelContext: ModelContext
    private let streakCalculator: StreakCalculator

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.streakCalculator = StreakCalculator(modelContext: modelContext)
    }

    // MARK: - Public Methods

    /// 今日の統計を取得または作成
    func getOrCreateTodayStats() -> DailyStats {
        return streakCalculator.getOrCreateTodayStats()
    }

    /// 学習記録を追加
    /// - Parameters:
    ///   - isNew: 新規カードかどうか
    ///   - isCorrect: 正解かどうか
    func recordReview(isNew: Bool, isCorrect: Bool) {
        let todayStats = getOrCreateTodayStats()
        todayStats.recordReview(isNew: isNew, isCorrect: isCorrect)
        streakCalculator.updateTodayStreak()
    }

    /// 学習時間を追加
    /// - Parameter seconds: 追加する秒数
    func addStudyTime(_ seconds: Int) {
        let todayStats = getOrCreateTodayStats()
        todayStats.addStudyTime(seconds)
    }

    /// セッション完了時の統計更新
    /// - Parameter session: 完了したセッション
    func recordSessionCompletion(_ session: StudySession) {
        let todayStats = getOrCreateTodayStats()

        // 学習時間を追加
        todayStats.addStudyTime(session.durationSeconds)

        // ストリークを更新
        streakCalculator.updateTodayStreak()
    }

    // MARK: - Statistics Queries

    /// 今日の統計サマリーを取得
    func getTodaySummary() -> DailyStatsSummary {
        let todayStats = getOrCreateTodayStats()
        let streakInfo = streakCalculator.getStreakInfo()

        return DailyStatsSummary(
            newCardsStudied: todayStats.newCardsCount,
            reviewCardsStudied: todayStats.reviewCardsCount,
            totalCardsStudied: todayStats.totalCardsStudied,
            correctCount: todayStats.correctCount,
            accuracy: todayStats.accuracy,
            studyTimeMinutes: todayStats.studyTimeMinutes,
            currentStreak: streakInfo.currentStreak,
            hasStudiedToday: streakInfo.hasStudiedToday
        )
    }

    /// 週間統計を取得
    func getWeeklyStats() -> [DailyStats] {
        let today = Calendar.current.startOfDay(for: Date())
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: today) else {
            return []
        }

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { stats in
                stats.date >= weekAgo
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching weekly stats: \(error)")
            return []
        }
    }

    /// 月間統計サマリーを取得
    func getMonthlyStats() -> MonthlyStatsSummary {
        let today = Calendar.current.startOfDay(for: Date())
        guard let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: today) else {
            return MonthlyStatsSummary.empty
        }

        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { stats in
                stats.date >= monthAgo
            }
        )

        do {
            let stats = try modelContext.fetch(descriptor)
            return calculateMonthlyStats(from: stats)
        } catch {
            print("Error fetching monthly stats: \(error)")
            return MonthlyStatsSummary.empty
        }
    }

    /// 全期間の統計を取得
    func getAllTimeStats() -> AllTimeStatsSummary {
        let descriptor = FetchDescriptor<DailyStats>()

        do {
            let allStats = try modelContext.fetch(descriptor)
            return calculateAllTimeStats(from: allStats)
        } catch {
            print("Error fetching all time stats: \(error)")
            return AllTimeStatsSummary.empty
        }
    }

    // MARK: - Private Methods

    private func calculateMonthlyStats(from stats: [DailyStats]) -> MonthlyStatsSummary {
        let totalCards = stats.reduce(0) { $0 + $1.totalCardsStudied }
        let totalCorrect = stats.reduce(0) { $0 + $1.correctCount }
        let totalStudyTime = stats.reduce(0) { $0 + $1.studyTimeSeconds }
        let daysStudied = stats.filter { $0.hasStudied }.count

        return MonthlyStatsSummary(
            totalCardsStudied: totalCards,
            correctCount: totalCorrect,
            totalStudyTimeMinutes: totalStudyTime / 60,
            daysStudied: daysStudied,
            averageCardsPerDay: daysStudied > 0 ? totalCards / daysStudied : 0
        )
    }

    private func calculateAllTimeStats(from stats: [DailyStats]) -> AllTimeStatsSummary {
        let totalCards = stats.reduce(0) { $0 + $1.totalCardsStudied }
        let totalCorrect = stats.reduce(0) { $0 + $1.correctCount }
        let totalStudyTime = stats.reduce(0) { $0 + $1.studyTimeSeconds }
        let daysStudied = stats.filter { $0.hasStudied }.count
        let longestStreak = streakCalculator.calculateLongestStreak()
        let currentStreak = streakCalculator.calculateCurrentStreak()

        return AllTimeStatsSummary(
            totalCardsStudied: totalCards,
            correctCount: totalCorrect,
            totalStudyTimeHours: totalStudyTime / 3600,
            daysStudied: daysStudied,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }
}

// MARK: - Summary Types

/// 今日の統計サマリー
struct DailyStatsSummary {
    let newCardsStudied: Int
    let reviewCardsStudied: Int
    let totalCardsStudied: Int
    let correctCount: Int
    let accuracy: Double
    let studyTimeMinutes: Int
    let currentStreak: Int
    let hasStudiedToday: Bool

    var accuracyPercent: Int {
        Int(accuracy * 100)
    }

    static let empty = DailyStatsSummary(
        newCardsStudied: 0,
        reviewCardsStudied: 0,
        totalCardsStudied: 0,
        correctCount: 0,
        accuracy: 0,
        studyTimeMinutes: 0,
        currentStreak: 0,
        hasStudiedToday: false
    )
}

/// 月間統計サマリー
struct MonthlyStatsSummary {
    let totalCardsStudied: Int
    let correctCount: Int
    let totalStudyTimeMinutes: Int
    let daysStudied: Int
    let averageCardsPerDay: Int

    var accuracy: Double {
        guard totalCardsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(totalCardsStudied)
    }

    static let empty = MonthlyStatsSummary(
        totalCardsStudied: 0,
        correctCount: 0,
        totalStudyTimeMinutes: 0,
        daysStudied: 0,
        averageCardsPerDay: 0
    )
}

/// 全期間統計サマリー
struct AllTimeStatsSummary {
    let totalCardsStudied: Int
    let correctCount: Int
    let totalStudyTimeHours: Int
    let daysStudied: Int
    let currentStreak: Int
    let longestStreak: Int

    var accuracy: Double {
        guard totalCardsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(totalCardsStudied)
    }

    static let empty = AllTimeStatsSummary(
        totalCardsStudied: 0,
        correctCount: 0,
        totalStudyTimeHours: 0,
        daysStudied: 0,
        currentStreak: 0,
        longestStreak: 0
    )
}
