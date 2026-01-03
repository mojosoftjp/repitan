import SwiftUI

extension Color {
    // MARK: - Primary Colors (rp = Repitan)

    /// メインブルー #4A90D9
    static let rpPrimary = Color("Primary")

    /// アクセントパープル #7B68EE
    static let rpSecondary = Color("Secondary")

    // MARK: - Semantic Colors

    /// 正解、成功 #4CAF50
    static let rpSuccess = Color("Success")

    /// 警告、注意 #FF9800
    static let rpWarning = Color("Warning")

    /// エラー、不正解 #F44336
    static let rpError = Color("Error")

    /// ストリーク炎 #FF5722
    static let rpStreak = Color("Streak")

    // MARK: - Rating Button Colors

    /// 全然ダメ #E57373
    static let rpAgain = Color("Again")

    /// 少し考えた #FFB74D
    static let rpHard = Color("Hard")

    /// 完璧 #81C784
    static let rpEasy = Color("Easy")

    // MARK: - Background Colors

    /// メイン背景 ライト: #F5F5F5, ダーク: #1C1C1E
    static let rpBackground = Color("Background")

    /// カード背景 ライト: #FFFFFF, ダーク: #2C2C2E
    static let rpCardBackground = Color("CardBg")

    /// グループ背景 ライト: #EFEFF4, ダーク: #000000
    static let rpGroupedBackground = Color("GroupedBg")

    // MARK: - Text Colors

    /// プライマリテキスト ライト: #1C1C1E, ダーク: #FFFFFF
    static let rpTextPrimary = Color("TextPrimary")

    /// セカンダリテキスト ライト: #8E8E93, ダーク: #8E8E93
    static let rpTextSecondary = Color("TextSecondary")

    // MARK: - Aliases (便利なエイリアス)

    /// テキスト色（rpTextPrimaryのエイリアス）
    static let rpText = rpTextPrimary

    /// カード背景色（rpCardBackgroundのエイリアス）
    static let rpCard = rpCardBackground

    /// ボーダー色
    static let rpBorder = Color(hex: "E0E0E0")
}

// MARK: - Fallback Colors (Asset Catalogなしでも動作)

extension Color {
    /// Asset Catalogがない場合のフォールバック
    static func rpColor(_ name: String) -> Color {
        switch name {
        case "Primary":
            return Color(red: 0.29, green: 0.56, blue: 0.85) // #4A90D9
        case "Secondary":
            return Color(red: 0.48, green: 0.41, blue: 0.93) // #7B68EE
        case "Success":
            return Color(red: 0.30, green: 0.69, blue: 0.31) // #4CAF50
        case "Warning":
            return Color(red: 1.00, green: 0.60, blue: 0.00) // #FF9800
        case "Error":
            return Color(red: 0.96, green: 0.26, blue: 0.21) // #F44336
        case "Streak":
            return Color(red: 1.00, green: 0.34, blue: 0.13) // #FF5722
        case "Again":
            return Color(red: 0.90, green: 0.45, blue: 0.45) // #E57373
        case "Hard":
            return Color(red: 1.00, green: 0.72, blue: 0.30) // #FFB74D
        case "Easy":
            return Color(red: 0.51, green: 0.78, blue: 0.52) // #81C784
        default:
            return Color.gray
        }
    }
}

// MARK: - Hex Color Initializer

extension Color {
    /// 16進数カラーコードから初期化
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
