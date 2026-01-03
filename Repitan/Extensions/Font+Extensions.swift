import SwiftUI

extension Font {
    // MARK: - Headings

    /// 大見出し (34pt, Bold)
    static let rpLargeTitle = Font.system(size: 34, weight: .bold)

    /// タイトル (24pt, Bold) - 汎用タイトル
    static let rpTitle = Font.system(size: 24, weight: .bold)

    /// タイトル1 (28pt, Bold)
    static let rpTitle1 = Font.system(size: 28, weight: .bold)

    /// タイトル2 (22pt, Bold)
    static let rpTitle2 = Font.system(size: 22, weight: .bold)

    /// タイトル3 (20pt, Semibold)
    static let rpTitle3 = Font.system(size: 20, weight: .semibold)

    /// ヘッドライン (17pt, Semibold)
    static let rpHeadline = Font.system(size: 17, weight: .semibold)

    // MARK: - Body Text

    /// 本文 (17pt, Regular)
    static let rpBody = Font.system(size: 17, weight: .regular)

    /// 本文太字 (17pt, Semibold)
    static let rpBodyBold = Font.system(size: 17, weight: .semibold)

    /// コールアウト (16pt, Regular)
    static let rpCallout = Font.system(size: 16, weight: .regular)

    // MARK: - Supporting Text

    /// サブヘッドライン (15pt, Regular)
    static let rpSubheadline = Font.system(size: 15, weight: .regular)

    /// 脚注 (13pt, Regular)
    static let rpFootnote = Font.system(size: 13, weight: .regular)

    /// キャプション (12pt, Regular) - 汎用キャプション
    static let rpCaption = Font.system(size: 12, weight: .regular)

    /// キャプション1 (12pt, Regular)
    static let rpCaption1 = Font.system(size: 12, weight: .regular)

    /// キャプション2 (11pt, Regular)
    static let rpCaption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Word Card Fonts

    /// 日本語表示 (32pt, Bold)
    static let rpWordJapanese = Font.system(size: 32, weight: .bold)

    /// 英単語表示 (28pt, Medium)
    static let rpWordEnglish = Font.system(size: 28, weight: .medium)

    /// 発音記号表示 (18pt, Regular)
    static let rpPhonetic = Font.system(size: 18, weight: .regular)

    // MARK: - Special Fonts

    /// ストリーク数字 (48pt, Bold)
    static let rpStreakNumber = Font.system(size: 48, weight: .bold, design: .rounded)

    /// 統計数字 (24pt, Semibold, Rounded)
    static let rpStatsNumber = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// ボタンテキスト (17pt, Semibold)
    static let rpButton = Font.system(size: 17, weight: .semibold)

    /// 小さなボタンテキスト (15pt, Medium)
    static let rpButtonSmall = Font.system(size: 15, weight: .medium)
}
