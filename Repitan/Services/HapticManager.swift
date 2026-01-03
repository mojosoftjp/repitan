import UIKit

/// 触覚フィードバック管理クラス
/// ボタン押下や正誤判定時のフィードバックを担当
final class HapticManager {
    static let shared = HapticManager()

    // ジェネレータは使用時に遅延初期化
    private var _lightImpact: UIImpactFeedbackGenerator?
    private var _mediumImpact: UIImpactFeedbackGenerator?
    private var _notification: UINotificationFeedbackGenerator?
    private var _selection: UISelectionFeedbackGenerator?

    private init() {}

    // MARK: - Lazy Generators

    private var lightImpact: UIImpactFeedbackGenerator {
        if _lightImpact == nil {
            _lightImpact = UIImpactFeedbackGenerator(style: .light)
        }
        return _lightImpact!
    }

    private var mediumImpact: UIImpactFeedbackGenerator {
        if _mediumImpact == nil {
            _mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        }
        return _mediumImpact!
    }

    private var notification: UINotificationFeedbackGenerator {
        if _notification == nil {
            _notification = UINotificationFeedbackGenerator()
        }
        return _notification!
    }

    private var selection: UISelectionFeedbackGenerator {
        if _selection == nil {
            _selection = UISelectionFeedbackGenerator()
        }
        return _selection!
    }

    // MARK: - Impact Feedback

    /// 軽いタップ（ボタン押下など）
    func lightTap() {
        lightImpact.impactOccurred()
    }

    /// 中程度のタップ（カード切り替えなど）
    func mediumTap() {
        mediumImpact.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// 成功（正解時）
    func success() {
        notification.notificationOccurred(.success)
    }

    /// エラー（不正解時）
    func error() {
        notification.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// 選択変更（リスト選択など）
    func selectionChanged() {
        selection.selectionChanged()
    }
}
