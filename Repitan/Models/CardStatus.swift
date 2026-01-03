import Foundation

/// カードの学習状態
enum CardStatus: String, Codable, CaseIterable {
    case new        // 未学習
    case learning   // 学習中（当日のステップ学習中）
    case review     // 復習待ち（卒業済み、次回復習日待ち）
    case relearning // 再学習中（復習で間違えた）
    case mastered   // 習得済み（interval >= 21日）

    var displayName: String {
        switch self {
        case .new: return "未学習"
        case .learning: return "学習中"
        case .review: return "復習待ち"
        case .relearning: return "再学習中"
        case .mastered: return "習得済み"
        }
    }
}

/// 回答方法
enum AnswerMethod: String, Codable, CaseIterable {
    case selfReport   // 自己申告（頭で考えて）
    case typing       // タイピング入力
    case voice        // 音声認識

    var displayName: String {
        switch self {
        case .selfReport: return "頭で考えて"
        case .typing: return "入力して"
        case .voice: return "声で"
        }
    }

    var iconName: String {
        switch self {
        case .selfReport: return "brain.head.profile"
        case .typing: return "keyboard"
        case .voice: return "mic.fill"
        }
    }
}

/// セッションタイプ
enum SessionType: String, Codable, CaseIterable {
    case newLearning    // 新規学習
    case review         // 復習のみ
    case mixed          // おまかせ（新規+復習）

    var displayName: String {
        switch self {
        case .newLearning: return "新規学習"
        case .review: return "復習"
        case .mixed: return "おまかせ学習"
        }
    }

    var iconName: String {
        switch self {
        case .newLearning: return "book.fill"
        case .review: return "arrow.clockwise"
        case .mixed: return "bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .newLearning: return "新しい単語を覚える"
        case .review: return "復習が必要な単語"
        case .mixed: return "新規 + 復習を自動選択"
        }
    }
}
