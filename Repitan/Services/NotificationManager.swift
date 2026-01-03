import Foundation
import UserNotifications

/// 復習通知を管理するマネージャー
/// まとめ通知方式：同じ時間帯の復習カードをまとめて1つの通知にする
/// 注意: フォアグラウンド通知はiOSのデフォルト動作（非表示）を使用
///       アプリ使用中は画面内の「待機中」表示で復習タイミングを確認
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    /// 保留中の学習通知情報（時間帯ごとにグループ化するため）
    private var pendingLearningNotifications: [Date: Int] = [:]

    // MARK: - Permission

    /// 通知許可をリクエスト
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// 通知許可状態を確認
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Grouped Notifications

    /// 学習カードの復習通知をスケジュール（まとめ通知）
    /// 同じ分に復習期限が来るカードは1つの通知にまとめる
    func scheduleLearningNotification(for card: Card, dueDate: Date) {
        // 過去の日時なら何もしない
        guard dueDate > Date() else {
            print("Learning notification skipped: dueDate is in the past")
            return
        }

        // 分単位で丸める（同じ分のカードはまとめる）
        let calendar = Calendar.current
        let roundedDate = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        ) ?? dueDate

        // 丸めた結果が過去になった場合は1分後にスケジュール
        let effectiveDate: Date
        if roundedDate <= Date() {
            effectiveDate = Date().addingTimeInterval(60)
        } else {
            effectiveDate = roundedDate
        }

        // 通知IDは時間ベース（同じ時間なら同じID → 上書きされる）
        let notificationId = "learning-\(Int(effectiveDate.timeIntervalSince1970))"

        print("Scheduling learning notification: \(notificationId) at \(effectiveDate)")

        // 既存の同時刻の通知を確認して更新
        updateGroupedNotification(
            identifier: notificationId,
            dueDate: effectiveDate,
            type: .learning
        )
    }

    /// 復習カードの日次通知をスケジュール（まとめ通知）
    /// 同じ日に復習期限が来るカードは1つの通知にまとめる
    /// 就寝前（21時）に通知：睡眠中の記憶固定化を活用
    func scheduleReviewNotification(for card: Card, dueDate: Date) {
        let calendar = Calendar.current

        // 復習日の夜9時を計算（就寝前の学習が記憶定着に最適）
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        dateComponents.hour = 21
        dateComponents.minute = 0

        guard let notificationDate = calendar.date(from: dateComponents) else { return }

        // 通知時刻が過去なら何もしない
        guard notificationDate > Date() else { return }

        // 日単位で丸める
        let startOfDay = calendar.startOfDay(for: dueDate)

        // 通知IDは日付ベース
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let notificationId = "review-\(dateFormatter.string(from: startOfDay))"

        // 既存の同日の通知を確認して更新
        updateGroupedNotification(
            identifier: notificationId,
            dueDate: notificationDate,
            type: .review
        )
    }

    private enum NotificationType {
        case learning
        case review
    }

    /// グループ化された通知を更新
    private func updateGroupedNotification(identifier: String, dueDate: Date, type: NotificationType) {
        let center = UNUserNotificationCenter.current()

        // 既存の通知を確認
        center.getPendingNotificationRequests { requests in

            let existingRequest = requests.first { $0.identifier == identifier }
            var cardCount = 1

            if let existing = existingRequest,
               let existingCount = existing.content.userInfo["cardCount"] as? Int {
                cardCount = existingCount + 1
            }

            // 新しい通知を作成
            let content = UNMutableNotificationContent()

            switch type {
            case .learning:
                content.title = "復習の時間です"
                if cardCount == 1 {
                    content.body = "復習時間になった単語があります"
                } else {
                    content.body = "\(cardCount)語の復習時間になりました"
                }
            case .review:
                content.title = "今日の復習"
                if cardCount == 1 {
                    content.body = "復習する単語があります"
                } else {
                    content.body = "\(cardCount)語の復習があります"
                }
            }

            content.sound = .default
            content.categoryIdentifier = "REVIEW_REMINDER"
            content.userInfo = ["cardCount": cardCount]

            let timeInterval = max(1, dueDate.timeIntervalSinceNow)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            // 既存の通知を削除してから新しい通知を追加
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule grouped notification: \(error)")
                } else {
                    print("Successfully scheduled notification: \(identifier), timeInterval: \(timeInterval)s")
                }
            }
        }
    }

    // MARK: - Cancel Notifications

    /// 特定のカードの通知をキャンセル
    /// まとめ通知方式では個別キャンセルは不要だが、互換性のため残す
    func cancelNotification(for cardId: UUID) {
        // まとめ通知方式では個別のカードIDで通知を管理していないため、
        // この関数は実質的に何もしない
        // 注意: カード数のカウントダウンは実装していない
        // （削除されたカード分を減らすと複雑になるため）
    }

    /// すべての通知をキャンセル
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// 学習通知をすべてキャンセル
    func cancelAllLearningNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let learningIds = requests
                .filter { $0.identifier.hasPrefix("learning-") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: learningIds)
        }
    }

    /// 復習通知をすべてキャンセル
    func cancelAllReviewNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let reviewIds = requests
                .filter { $0.identifier.hasPrefix("review-") }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reviewIds)
        }
    }

    /// 保留中の通知を取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - Session Learning Notification

    /// セッション完了時に学習中カードの通知をまとめてスケジュール
    /// - Parameters:
    ///   - cardCount: 学習中のカード数
    ///   - dueDate: 復習時刻
    func scheduleSessionLearningNotification(cardCount: Int, dueDate: Date) {
        // 過去の日時なら何もしない
        guard dueDate > Date() else {
            print("Session learning notification skipped: dueDate is in the past")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "復習の時間です"
        if cardCount == 1 {
            content.body = "復習時間になった単語があります"
        } else {
            content.body = "\(cardCount)語の復習時間になりました"
        }
        content.sound = .default
        content.categoryIdentifier = "REVIEW_REMINDER"

        let timeInterval = max(1, dueDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        // 固定IDを使用して、常に1つの通知のみ存在するようにする
        let notificationId = "session-learning"

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        // 既存の同じIDの通知を削除してから追加（同じIDなら自動的に上書きされる）
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule session learning notification: \(error)")
            } else {
                print("Scheduled session learning notification: \(cardCount) cards in \(Int(timeInterval))s")
            }
        }
    }

    // MARK: - Daily Summary Notification

    /// 毎日の復習リマインダーをスケジュール（夜9時）
    /// 就寝前の学習が記憶定着に最適（睡眠中の記憶固定化を活用）
    /// - Parameter reviewCount: 復習待ちカードの件数（0の場合は励ましメッセージ）
    func scheduleDailySummaryNotification(reviewCount: Int = -1) {
        let content = UNMutableNotificationContent()
        content.title = "今日の復習"

        // 復習件数に応じてメッセージを変更
        if reviewCount == 0 {
            content.body = "復習はありません。新しい単語を学習しましょう！"
        } else if reviewCount > 0 {
            content.body = "寝る前に\(reviewCount)語の復習をしましょう。睡眠中に記憶が定着します！"
        } else {
            // reviewCount < 0 の場合は汎用メッセージ（件数不明時）
            content.body = "寝る前の学習は記憶定着に効果的です！"
        }

        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        // 夜9時に通知（就寝前の学習を促す）
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily summary: \(error)")
            }
        }
    }

    /// 毎日のリマインダーをキャンセル
    func cancelDailySummaryNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-summary"])
    }
}
