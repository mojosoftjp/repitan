import Foundation

/// 単語帳カテゴリ管理
/// システム定義のカテゴリとカスタムカテゴリを管理
struct DeckCategoryManager {

    /// カテゴリ情報
    struct Category: Identifiable, Hashable {
        let id: String
        let name: String
        let icon: String
        let isSystem: Bool

        init(id: String, name: String, icon: String, isSystem: Bool = true) {
            self.id = id
            self.name = name
            self.icon = icon
            self.isSystem = isSystem
        }
    }

    /// システム定義のカテゴリ
    static let systemCategories: [Category] = [
        // 学年レベル別
        Category(id: "junior_high_1", name: "中1レベル", icon: "📘"),
        Category(id: "junior_high_2", name: "中2レベル", icon: "📗"),
        Category(id: "junior_high_3", name: "中3レベル", icon: "📙"),
        // 特別単語帳
        Category(id: "irregular_verbs", name: "不規則動詞", icon: "🔄"),
        // カスタム
        Category(id: "custom", name: "カスタム", icon: "📝", isSystem: false),
    ]

    /// カテゴリIDから表示名を取得
    /// - Parameter categoryId: カテゴリID
    /// - Returns: 表示名（見つからない場合はカテゴリIDをそのまま返す）
    static func displayName(for categoryId: String) -> String {
        systemCategories.first { $0.id == categoryId }?.name ?? categoryId
    }

    /// カテゴリIDからアイコンを取得
    /// - Parameter categoryId: カテゴリID
    /// - Returns: アイコン（見つからない場合はデフォルトアイコン）
    static func icon(for categoryId: String) -> String {
        systemCategories.first { $0.id == categoryId }?.icon ?? "📝"
    }

    /// カテゴリIDからCategoryオブジェクトを取得
    /// - Parameter categoryId: カテゴリID
    /// - Returns: Categoryオブジェクト（見つからない場合はカスタムカテゴリとして生成）
    static func category(for categoryId: String) -> Category {
        systemCategories.first { $0.id == categoryId }
            ?? Category(id: categoryId, name: categoryId, icon: "📝", isSystem: false)
    }

    /// システムカテゴリかどうかを判定
    /// - Parameter categoryId: カテゴリID
    /// - Returns: システムカテゴリならtrue
    static func isSystemCategory(_ categoryId: String) -> Bool {
        systemCategories.first { $0.id == categoryId }?.isSystem ?? false
    }

    /// 学年レベル別カテゴリのみを取得
    static var gradeLevelCategories: [Category] {
        systemCategories.filter { $0.id.hasPrefix("junior_high_") }
    }

    /// カテゴリIDから学年を抽出
    /// - Parameter categoryId: カテゴリID
    /// - Returns: 学年（1, 2, 3）、抽出できない場合はnil
    static func gradeFromCategory(_ categoryId: String) -> Int? {
        if categoryId.hasSuffix("_1") { return 1 }
        if categoryId.hasSuffix("_2") { return 2 }
        if categoryId.hasSuffix("_3") { return 3 }
        return nil
    }
}
