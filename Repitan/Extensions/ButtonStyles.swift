import SwiftUI

// MARK: - Primary Button Style

/// プライマリボタンスタイル
/// メインアクション用の塗りつぶしボタン
struct RPPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpBodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.rpPrimary : Color.gray)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// セカンダリボタンスタイル
/// サブアクション用のアウトラインボタン
struct RPSecondaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpBodyBold)
            .foregroundColor(isEnabled ? .rpPrimary : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background((isEnabled ? Color.rpPrimary : Color.gray).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? Color.rpPrimary : Color.gray, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Rating Button Styles

/// Again評価ボタンスタイル（全然ダメ）
struct RPAgainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpButton)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.rpAgain)
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Hard評価ボタンスタイル（少し考えた）
struct RPHardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpButton)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.rpHard)
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Easy評価ボタンスタイル（完璧！）
struct RPEasyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpButton)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.rpEasy)
            .cornerRadius(16)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style

/// アイコンボタンスタイル
struct RPIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(Color.rpCardBackground)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

/// 破壊的アクション用ボタンスタイル
struct RPDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpBodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.rpError)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Style Modifier

/// カードスタイルモディファイア
struct RPCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.rpCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// カードスタイルを適用
    func rpCardStyle(padding: CGFloat = 16) -> some View {
        modifier(RPCardStyle(padding: padding))
    }
}

// MARK: - Floating Action Button Style

/// フローティングアクションボタンスタイル
struct RPFloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rpTitle3)
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(Color.rpPrimary)
            .clipShape(Circle())
            .shadow(color: Color.rpPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
