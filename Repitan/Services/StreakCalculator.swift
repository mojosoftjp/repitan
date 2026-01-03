import Foundation
import SwiftData

/// ストリーク（連続学習日数）計算サービス
@MainActor
class StreakCalculator {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 現在のストリークを計算
    /// - Returns: 連続学習日数
    func calculateCurrentStreak() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        var currentDate = today
        var streak = 0

        // 今日学習したかチェック
        if hasStudied(on: today) {
            streak = 1
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        } else {
            // 今日まだ学習していない場合、昨日からチェック
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        }

        // 過去の連続日数をカウント
        while hasStudied(on: currentDate) {
            streak += 1
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }

    /// 最長ストリークを計算
    /// - Returns: 過去最長の連続学習日数
    func calculateLongestStreak() -> Int {
        let allStats = fetchAllDailyStats()
        guard !allStats.isEmpty else { return 0 }

        // 日付でソート
        let sortedStats = allStats.sorted { $0.date < $1.date }

        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?

        for stats in sortedStats {
            guard stats.hasStudied else {
                currentStreak = 0
                previousDate = stats.date
                continue
            }

            if let prevDate = previousDate {
                let daysDifference = Calendar.current.dateComponents([.day], from: prevDate, to: stats.date).day ?? 0
                if daysDifference == 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            longestStreak = max(longestStreak, currentStreak)
            previousDate = stats.date
        }

        return longestStreak
    }

    /// 指定日に学習したかをチェック
    /// - Parameter date: チェックする日付
    /// - Returns: 学習した場合true
    func hasStudied(on date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let stats = fetchDailyStats(for: startOfDay)
        return stats?.hasStudied ?? false
    }

    /// 今日のDailyStatsを取得または作成
    /// - Returns: 今日のDailyStats
    func getOrCreateTodayStats() -> DailyStats {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = fetchDailyStats(for: today) {
            return existing
        }

        let newStats = DailyStats(date: today)
        newStats.currentStreak = calculateCurrentStreak()
        modelContext.insert(newStats)
        return newStats
    }

    /// 今日のストリークを更新
    func updateTodayStreak() {
        let todayStats = getOrCreateTodayStats()
        todayStats.currentStreak = calculateCurrentStreak()
    }

    // MARK: - Private Methods

    private func fetchDailyStats(for date: Date) -> DailyStats? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyStats>(
            predicate: #Predicate { stats in
                stats.date == startOfDay
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Error fetching DailyStats: \(error)")
            return nil
        }
    }

    private func fetchAllDailyStats() -> [DailyStats] {
        let descriptor = FetchDescriptor<DailyStats>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching all DailyStats: \(error)")
            return []
        }
    }
}

// MARK: - Streak Information

extension StreakCalculator {
    /// ストリーク情報
    struct StreakInfo {
        let currentStreak: Int
        let longestStreak: Int
        let hasStudiedToday: Bool
        let needsStudyToday: Bool

        var encouragementMessage: String {
            if hasStudiedToday {
                if currentStreak >= 30 {
                    return "すごい！\(currentStreak)日連続達成！🎉"
                } else if currentStreak >= 7 {
                    return "\(currentStreak)日連続！この調子！💪"
                } else if currentStreak >= 3 {
                    return "\(currentStreak)日連続！頑張ってるね！✨"
                } else {
                    return "今日も学習完了！🔥"
                }
            } else {
                if currentStreak > 0 {
                    return "今日も学習して\(currentStreak + 1)日連続を目指そう！"
                } else {
                    return "今日から新しいストリークを始めよう！"
                }
            }
        }
    }

    /// 現在のストリーク情報を取得
    func getStreakInfo() -> StreakInfo {
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        let hasStudiedToday = hasStudied(on: Date())

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasStudiedToday: hasStudiedToday,
            needsStudyToday: !hasStudiedToday
        )
    }
}
