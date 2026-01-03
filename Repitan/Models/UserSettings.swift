import Foundation
import SwiftData

/// ユーザー設定
/// アプリ全体の設定とユーザーのプリファレンスを保持
@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID

    // MARK: - Learning Goals

    /// 1日の新規カード目標数
    var dailyNewCardGoal: Int

    /// 1日の復習カード上限数
    var dailyReviewLimit: Int

    // MARK: - Notification Settings

    /// リマインダー通知時刻
    var notificationTime: Date?

    /// 通知が有効か
    var notificationEnabled: Bool

    // MARK: - Audio & Haptic Settings

    /// サウンド効果が有効か
    var soundEnabled: Bool

    /// 触覚フィードバックが有効か
    var hapticEnabled: Bool

    // MARK: - Learning Settings

    /// 優先する回答方法
    var preferredAnswerMethod: AnswerMethod

    /// 自動発音再生が有効か
    var autoPlayPronunciation: Bool

    /// 音声認識モードが有効か
    var useSpeechRecognition: Bool

    // MARK: - Premium Settings

    /// プレミアム（広告削除）済みか
    var isPremium: Bool

    // MARK: - Onboarding

    /// オンボーディングを完了したか
    var hasCompletedOnboarding: Bool

    // MARK: - User Profile

    /// ユーザー名（レポート表示用）
    var userName: String?

    /// 選択中の教科書ID
    var selectedTextbook: String?

    /// 選択中の学年（1, 2, 3）
    var selectedGrade: Int?

    // MARK: - SM-2 Algorithm Settings

    /// 学習ステップ（分単位）
    /// デフォルト: [3, 20] = 3分後、20分後
    var learningSteps: [Int]

    /// 再学習ステップ（分単位）
    /// デフォルト: [20] = 20分後
    var relearningSteps: [Int]

    /// 卒業時の初回間隔（日）
    var graduatingInterval: Int

    /// 「簡単」時の初回間隔（日）
    var easyInterval: Int

    /// 最大間隔（日）
    var maximumInterval: Int

    // MARK: - Statistics

    /// アプリ初回起動日
    var firstLaunchDate: Date?

    /// 最後の学習日
    var lastStudyDate: Date?

    // MARK: - Migration Flags

    /// 学習ステップ移行済みフラグ（v1.1: [1,10]→[3,20]）
    var hasLearningStepsMigrated: Bool

    // MARK: - Initialization

    init() {
        self.id = UUID()
        self.dailyNewCardGoal = 10
        self.dailyReviewLimit = 50
        self.notificationEnabled = false
        self.soundEnabled = true
        self.hapticEnabled = true
        self.preferredAnswerMethod = .typing
        self.autoPlayPronunciation = true
        self.useSpeechRecognition = false
        self.isPremium = false
        self.hasCompletedOnboarding = false
        self.learningSteps = [3, 20]
        self.relearningSteps = [20]
        self.graduatingInterval = 1
        self.easyInterval = 4
        self.maximumInterval = 365
        self.firstLaunchDate = Date()
        self.hasLearningStepsMigrated = true  // 新規ユーザーは移行不要
    }

    // MARK: - Computed Properties

    /// 選択中の教科書のカテゴリID
    var selectedCategoryId: String? {
        guard let textbook = selectedTextbook, let grade = selectedGrade else {
            return nil
        }
        let prefix: String
        switch textbook.lowercased() {
        case "new horizon", "new_horizon":
            prefix = "new_horizon"
        case "sunshine":
            prefix = "sunshine"
        case "blue sky", "blue_sky":
            prefix = "blue_sky"
        default:
            return nil
        }
        return "\(prefix)_\(grade)"
    }

    /// 選択中の教科書の表示名
    var selectedTextbookDisplayName: String? {
        guard let categoryId = selectedCategoryId else { return nil }
        return DeckCategoryManager.displayName(for: categoryId)
    }
}

// MARK: - Default Settings

extension UserSettings {
    /// デフォルト設定を作成
    static func createDefault() -> UserSettings {
        UserSettings()
    }

    /// 学習ステップを分から秒に変換
    func learningStepsInSeconds() -> [Int] {
        learningSteps.map { $0 * 60 }
    }

    /// 再学習ステップを分から秒に変換
    func relearningStepsInSeconds() -> [Int] {
        relearningSteps.map { $0 * 60 }
    }
}
