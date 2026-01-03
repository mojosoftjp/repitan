import Foundation
import SwiftData

/// 実績（アチーブメント）
/// ユーザーの達成した実績を記録
@Model
final class Achievement {
    @Attribute(.unique) var id: UUID

    /// 実績タイプ
    var achievementType: AchievementType

    /// 達成日時
    var unlockedAt: Date

    /// 達成時の値（例：連続日数、カード数など）
    var value: Int?

    // MARK: - Initialization

    init(type: AchievementType, value: Int? = nil) {
        self.id = UUID()
        self.achievementType = type
        self.unlockedAt = Date()
        self.value = value
    }

    // MARK: - Computed Properties

    /// 達成からの経過日数
    var daysSinceUnlocked: Int {
        Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
    }
}

// MARK: - Achievement Type

/// 実績の種類
enum AchievementType: String, Codable, CaseIterable {
    // ストリーク系
    case streak3       // 3日連続
    case streak7       // 7日連続
    case streak14      // 14日連続
    case streak30      // 30日連続
    case streak100     // 100日連続

    // カード数系
    case cards10       // 10語習得
    case cards50       // 50語習得
    case cards100      // 100語習得
    case cards500      // 500語習得
    case cards1000     // 1000語習得

    // セッション系
    case firstSession  // 初めての学習
    case perfectSession // パーフェクトセッション（全問正解）
    case speedSession  // スピードセッション（10問1分以内）

    // その他
    case earlyBird     // 朝の学習（6時〜9時）
    case nightOwl      // 夜の学習（21時〜24時）
    case weekendWarrior // 週末学習

    /// 表示名
    var displayName: String {
        switch self {
        case .streak3: return "3日連続"
        case .streak7: return "1週間継続"
        case .streak14: return "2週間継続"
        case .streak30: return "1ヶ月継続"
        case .streak100: return "100日達成"
        case .cards10: return "10語マスター"
        case .cards50: return "50語マスター"
        case .cards100: return "100語マスター"
        case .cards500: return "500語マスター"
        case .cards1000: return "1000語マスター"
        case .firstSession: return "はじめの一歩"
        case .perfectSession: return "完璧！"
        case .speedSession: return "スピードスター"
        case .earlyBird: return "早起きは三文の徳"
        case .nightOwl: return "夜型学習者"
        case .weekendWarrior: return "週末の戦士"
        }
    }

    /// 説明文
    var description: String {
        switch self {
        case .streak3: return "3日連続で学習しました"
        case .streak7: return "1週間毎日学習しました"
        case .streak14: return "2週間毎日学習しました"
        case .streak30: return "1ヶ月毎日学習しました"
        case .streak100: return "100日連続で学習しました"
        case .cards10: return "10語の単語を習得しました"
        case .cards50: return "50語の単語を習得しました"
        case .cards100: return "100語の単語を習得しました"
        case .cards500: return "500語の単語を習得しました"
        case .cards1000: return "1000語の単語を習得しました"
        case .firstSession: return "最初の学習セッションを完了しました"
        case .perfectSession: return "全問正解でセッションを完了しました"
        case .speedSession: return "10問を1分以内に回答しました"
        case .earlyBird: return "朝6時〜9時に学習しました"
        case .nightOwl: return "夜21時〜24時に学習しました"
        case .weekendWarrior: return "週末に学習しました"
        }
    }

    /// アイコン
    var icon: String {
        switch self {
        case .streak3, .streak7, .streak14, .streak30, .streak100:
            return "🔥"
        case .cards10, .cards50, .cards100, .cards500, .cards1000:
            return "📚"
        case .firstSession:
            return "🎉"
        case .perfectSession:
            return "💯"
        case .speedSession:
            return "⚡️"
        case .earlyBird:
            return "🌅"
        case .nightOwl:
            return "🌙"
        case .weekendWarrior:
            return "💪"
        }
    }

    /// 達成条件の閾値
    var threshold: Int? {
        switch self {
        case .streak3: return 3
        case .streak7: return 7
        case .streak14: return 14
        case .streak30: return 30
        case .streak100: return 100
        case .cards10: return 10
        case .cards50: return 50
        case .cards100: return 100
        case .cards500: return 500
        case .cards1000: return 1000
        default: return nil
        }
    }
}

// MARK: - Achievement Categories

extension AchievementType {
    /// カテゴリ
    enum Category: String, CaseIterable {
        case streak = "継続"
        case vocabulary = "語彙"
        case session = "セッション"
        case special = "スペシャル"
    }

    /// このタイプのカテゴリ
    var category: Category {
        switch self {
        case .streak3, .streak7, .streak14, .streak30, .streak100:
            return .streak
        case .cards10, .cards50, .cards100, .cards500, .cards1000:
            return .vocabulary
        case .firstSession, .perfectSession, .speedSession:
            return .session
        case .earlyBird, .nightOwl, .weekendWarrior:
            return .special
        }
    }
}
