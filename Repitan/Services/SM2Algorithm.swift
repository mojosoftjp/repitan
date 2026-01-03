import Foundation

/// SM-2ベースの間隔反復アルゴリズム（Anki風の学習ステップ付き）
///
/// SM-2（SuperMemo 2）をベースに、Ankiの学習ステップシステムを取り入れた改良版。
/// 新規カードは学習ステップ（3分→20分）を経て卒業し、復習フェーズへ移行する。
struct SM2Algorithm {

    // MARK: - Default Settings

    /// デフォルトの学習ステップ（分単位）
    static let defaultLearningSteps: [Int] = [3, 20]

    /// デフォルトの再学習ステップ（分単位）
    static let defaultRelearningSteps: [Int] = [20]

    /// 卒業時の初回間隔（日）
    static let defaultGraduatingInterval: Int = 1

    /// 「簡単」評価時の初回間隔（日）
    static let defaultEasyInterval: Int = 4

    /// 最大間隔（日）
    static let defaultMaximumInterval: Int = 365

    /// 最小EF（Ease Factor）
    static let minimumEaseFactor: Double = 1.3

    /// 最大EF
    static let maximumEaseFactor: Double = 3.0

    /// 初期EF
    static let initialEaseFactor: Double = 2.5

    // MARK: - Simple Rating

    /// 3段階評価
    enum SimpleRating: Int, CaseIterable {
        case again = 0    // 全然ダメ 😰
        case hard = 2     // 少し考えた 🤔
        case easy = 4     // 完璧！ 😊

        var displayEmoji: String {
            switch self {
            case .again: return "😰"
            case .hard: return "🤔"
            case .easy: return "😊"
            }
        }

        var displayText: String {
            switch self {
            case .again: return "全然ダメ"
            case .hard: return "少し考えた"
            case .easy: return "完璧！"
            }
        }

        /// SM-2の品質値に変換
        var quality: Int {
            rawValue
        }

        /// 正解とみなすか
        var isCorrect: Bool {
            self != .again
        }
    }

    // MARK: - Schedule Result

    /// 計算結果
    struct ScheduleResult {
        let easeFactor: Double
        let interval: Int
        let repetitions: Int
        let nextReviewDate: Date
        let lapses: Int
        let learningStep: Int
        let learningDueDate: Date?
        let newStatus: CardStatus

        /// デバッグ用の説明
        var debugDescription: String {
            """
            ScheduleResult:
              easeFactor: \(String(format: "%.2f", easeFactor))
              interval: \(interval) days
              repetitions: \(repetitions)
              nextReviewDate: \(nextReviewDate)
              lapses: \(lapses)
              learningStep: \(learningStep)
              learningDueDate: \(learningDueDate?.description ?? "nil")
              newStatus: \(newStatus)
            """
        }
    }

    // MARK: - Preview Text

    /// 次回復習までの表示テキストを取得（評価ボタン表示用）
    static func nextReviewText(for card: Card, rating: SimpleRating, settings: UserSettings? = nil) -> String {
        let learningSteps = settings?.learningSteps ?? defaultLearningSteps
        let relearningSteps = settings?.relearningSteps ?? defaultRelearningSteps
        let graduatingInterval = settings?.graduatingInterval ?? defaultGraduatingInterval
        let easyInterval = settings?.easyInterval ?? defaultEasyInterval

        switch card.status {
        case .new, .learning:
            return nextReviewTextForLearning(
                card: card,
                rating: rating,
                learningSteps: learningSteps,
                graduatingInterval: graduatingInterval,
                easyInterval: easyInterval
            )

        case .review, .mastered:
            return nextReviewTextForReview(
                card: card,
                rating: rating,
                relearningSteps: relearningSteps
            )

        case .relearning:
            return nextReviewTextForRelearning(
                card: card,
                rating: rating,
                relearningSteps: relearningSteps
            )
        }
    }

    private static func nextReviewTextForLearning(
        card: Card,
        rating: SimpleRating,
        learningSteps: [Int],
        graduatingInterval: Int,
        easyInterval: Int
    ) -> String {
        switch rating {
        case .again:
            return "\(learningSteps.first ?? 1)分後"
        case .hard:
            let currentStep = max(0, card.learningStep)
            if currentStep < learningSteps.count - 1 {
                return "\(learningSteps[currentStep + 1])分後"
            } else {
                return "\(graduatingInterval)日後"
            }
        case .easy:
            return "\(easyInterval)日後"
        }
    }

    private static func nextReviewTextForReview(
        card: Card,
        rating: SimpleRating,
        relearningSteps: [Int]
    ) -> String {
        switch rating {
        case .again:
            return "\(relearningSteps.first ?? 10)分後"
        case .hard:
            let newInterval = max(1, Int(Double(card.interval) * 1.2))
            return formatIntervalText(newInterval)
        case .easy:
            let newInterval = max(1, Int(Double(card.interval) * card.easeFactor))
            return formatIntervalText(newInterval)
        }
    }

    private static func nextReviewTextForRelearning(
        card: Card,
        rating: SimpleRating,
        relearningSteps: [Int]
    ) -> String {
        switch rating {
        case .again:
            return "\(relearningSteps.first ?? 10)分後"
        case .hard, .easy:
            let interval = max(1, card.interval)
            return formatIntervalText(interval)
        }
    }

    private static func formatIntervalText(_ days: Int) -> String {
        if days == 1 {
            return "1日後"
        } else if days < 7 {
            return "\(days)日後"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)週間後"
        } else {
            let months = days / 30
            return "\(months)ヶ月後"
        }
    }

    // MARK: - Main Calculation

    /// スケジュール計算（メイン関数）
    static func calculate(
        card: Card,
        rating: SimpleRating,
        settings: UserSettings? = nil
    ) -> ScheduleResult {
        let learningSteps = settings?.learningSteps ?? defaultLearningSteps
        let relearningSteps = settings?.relearningSteps ?? defaultRelearningSteps
        let graduatingInterval = settings?.graduatingInterval ?? defaultGraduatingInterval
        let easyInterval = settings?.easyInterval ?? defaultEasyInterval
        let maximumInterval = settings?.maximumInterval ?? defaultMaximumInterval

        switch card.status {
        case .new, .learning:
            return calculateForLearning(
                card: card,
                rating: rating,
                learningSteps: learningSteps,
                graduatingInterval: graduatingInterval,
                easyInterval: easyInterval,
                maximumInterval: maximumInterval
            )

        case .review, .mastered:
            return calculateForReview(
                card: card,
                rating: rating,
                relearningSteps: relearningSteps,
                maximumInterval: maximumInterval
            )

        case .relearning:
            return calculateForRelearning(
                card: card,
                rating: rating,
                relearningSteps: relearningSteps,
                maximumInterval: maximumInterval
            )
        }
    }

    // MARK: - Learning Phase Calculation

    /// 新規・学習中カードの計算
    private static func calculateForLearning(
        card: Card,
        rating: SimpleRating,
        learningSteps: [Int],
        graduatingInterval: Int,
        easyInterval: Int,
        maximumInterval: Int
    ) -> ScheduleResult {
        var easeFactor = card.easeFactor
        var learningStep = max(0, card.learningStep)
        var interval = card.interval
        var repetitions = card.repetitions
        let lapses = card.lapses
        var newStatus: CardStatus = .learning
        var learningDueDate: Date? = nil
        var nextReviewDate = card.nextReviewDate

        switch rating {
        case .again:
            // 最初のステップに戻る
            learningStep = 0
            learningDueDate = Calendar.current.date(
                byAdding: .minute,
                value: learningSteps.first ?? 1,
                to: Date()
            )
            newStatus = .learning

        case .hard:
            // 次のステップへ進む
            learningStep += 1
            if learningStep >= learningSteps.count {
                // 卒業！
                interval = min(graduatingInterval, maximumInterval)
                nextReviewDate = Calendar.current.date(
                    byAdding: .day,
                    value: interval,
                    to: Date()
                ) ?? Date()
                learningStep = -1  // 卒業済みマーク
                newStatus = .review
                repetitions = 1
            } else {
                // 次の学習ステップへ
                learningDueDate = Calendar.current.date(
                    byAdding: .minute,
                    value: learningSteps[learningStep],
                    to: Date()
                )
                newStatus = .learning
            }

        case .easy:
            // 即卒業（Easyボーナス）
            interval = min(easyInterval, maximumInterval)
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: interval,
                to: Date()
            ) ?? Date()
            learningStep = -1
            newStatus = .review
            repetitions = 1
            // EFを少し上げる（Easyボーナス）
            easeFactor = min(maximumEaseFactor, easeFactor + 0.15)
        }

        return ScheduleResult(
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lapses: lapses,
            learningStep: learningStep,
            learningDueDate: learningDueDate,
            newStatus: newStatus
        )
    }

    // MARK: - Review Phase Calculation

    /// 復習カードの計算
    private static func calculateForReview(
        card: Card,
        rating: SimpleRating,
        relearningSteps: [Int],
        maximumInterval: Int
    ) -> ScheduleResult {
        var easeFactor = card.easeFactor
        var interval = card.interval
        var repetitions = card.repetitions
        var lapses = card.lapses
        var newStatus: CardStatus = .review
        var learningDueDate: Date? = nil
        var nextReviewDate = card.nextReviewDate

        switch rating {
        case .again:
            // 再学習へ移行
            lapses += 1
            repetitions = 0
            // EFを下げる
            easeFactor = max(minimumEaseFactor, easeFactor - 0.2)
            // 再学習ステップの最初から
            learningDueDate = Calendar.current.date(
                byAdding: .minute,
                value: relearningSteps.first ?? 10,
                to: Date()
            )
            newStatus = .relearning
            // 間隔を短縮（現在の20%）
            interval = max(1, Int(Double(interval) * 0.2))

        case .hard:
            // 間隔を少し延ばす（×1.2）
            interval = min(maximumInterval, max(1, Int(Double(interval) * 1.2)))
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: interval,
                to: Date()
            ) ?? Date()
            // EFを少し下げる
            easeFactor = max(minimumEaseFactor, easeFactor - 0.15)
            repetitions += 1
            newStatus = interval >= 21 ? .mastered : .review

        case .easy:
            // 間隔を大きく延ばす（×EF）
            interval = min(maximumInterval, max(1, Int(Double(interval) * easeFactor)))
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: interval,
                to: Date()
            ) ?? Date()
            // EFを上げる
            easeFactor = min(maximumEaseFactor, easeFactor + 0.1)
            repetitions += 1
            newStatus = interval >= 21 ? .mastered : .review
        }

        return ScheduleResult(
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lapses: lapses,
            learningStep: -1,
            learningDueDate: learningDueDate,
            newStatus: newStatus
        )
    }

    // MARK: - Relearning Phase Calculation

    /// 再学習カードの計算
    private static func calculateForRelearning(
        card: Card,
        rating: SimpleRating,
        relearningSteps: [Int],
        maximumInterval: Int
    ) -> ScheduleResult {
        var easeFactor = card.easeFactor
        var interval = card.interval
        var repetitions = card.repetitions
        let lapses = card.lapses
        var newStatus: CardStatus = .relearning
        var learningDueDate: Date? = nil
        var nextReviewDate = card.nextReviewDate

        switch rating {
        case .again:
            // 再度、再学習ステップの最初から
            learningDueDate = Calendar.current.date(
                byAdding: .minute,
                value: relearningSteps.first ?? 10,
                to: Date()
            )
            newStatus = .relearning

        case .hard:
            // 再学習完了 → 復習へ
            interval = max(1, interval)
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: interval,
                to: Date()
            ) ?? Date()
            newStatus = .review
            repetitions = 1

        case .easy:
            // 再学習完了 → 復習へ（EFボーナス）
            interval = max(1, interval)
            nextReviewDate = Calendar.current.date(
                byAdding: .day,
                value: interval,
                to: Date()
            ) ?? Date()
            newStatus = .review
            repetitions = 1
            // EFを少し上げる
            easeFactor = min(maximumEaseFactor, easeFactor + 0.1)
        }

        return ScheduleResult(
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            nextReviewDate: nextReviewDate,
            lapses: lapses,
            learningStep: -1,
            learningDueDate: learningDueDate,
            newStatus: newStatus
        )
    }

    // MARK: - Apply Result

    /// カードに結果を適用
    static func apply(result: ScheduleResult, to card: Card) {
        card.easeFactor = result.easeFactor
        card.interval = result.interval
        card.repetitions = result.repetitions
        card.nextReviewDate = result.nextReviewDate
        card.lapses = result.lapses
        card.learningStep = result.learningStep
        card.learningDueDate = result.learningDueDate
        card.status = result.newStatus
        card.updatedAt = Date()
    }

    /// カードを評価して結果を適用（便利メソッド）
    /// 注意: 通知はセッション完了時にまとめてスケジュールされるため、ここでは行わない
    static func rate(card: Card, with rating: SimpleRating, settings: UserSettings? = nil) {
        let result = calculate(card: card, rating: rating, settings: settings)
        apply(result: result, to: card)
        // 通知はTestView.scheduleSessionNotifications()でまとめてスケジュール
    }

    // MARK: - Notifications

    /// 復習通知をスケジュール（公開メソッド）
    /// TestViewなど外部から呼び出す場合に使用
    static func scheduleNotificationIfEnabled(for card: Card, result: ScheduleResult, settings: UserSettings?) {
        // 通知が有効な場合のみスケジュール
        let notificationEnabled = settings?.notificationEnabled ?? false
        print("SM2: scheduleNotificationIfEnabled - notificationEnabled=\(notificationEnabled), newStatus=\(result.newStatus)")
        if notificationEnabled {
            scheduleNotification(for: card, result: result)
        } else {
            print("SM2: Notification skipped - notificationEnabled is false")
        }
    }

    /// 復習通知をスケジュール
    private static func scheduleNotification(for card: Card, result: ScheduleResult) {
        let notificationManager = NotificationManager.shared

        // 既存の通知をキャンセル
        notificationManager.cancelNotification(for: card.id)

        switch result.newStatus {
        case .learning, .relearning:
            // 学習中カードは learningDueDate に通知
            if let dueDate = result.learningDueDate {
                print("SM2: Scheduling learning notification for \(dueDate)")
                notificationManager.scheduleLearningNotification(for: card, dueDate: dueDate)
            } else {
                print("SM2: No learningDueDate for learning/relearning card")
            }

        case .review, .mastered:
            // 復習カードは nextReviewDate に通知
            print("SM2: Scheduling review notification for \(result.nextReviewDate)")
            notificationManager.scheduleReviewNotification(for: card, dueDate: result.nextReviewDate)

        case .new:
            // 新規カードは通知なし
            print("SM2: No notification for new card")
            break
        }
    }
}
