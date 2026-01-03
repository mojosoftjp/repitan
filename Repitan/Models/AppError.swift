import Foundation

/// アプリケーションエラー
enum AppError: LocalizedError {
    // データ関連
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case cardNotFound
    case deckNotFound

    // 音声認識関連
    case speechRecognitionNotAuthorized
    case speechRecognitionFailed(String)
    case microphoneNotAvailable

    // 課金関連
    case purchaseFailed(String)
    case purchaseNotVerified
    case productNotFound

    // ファイル関連
    case csvParsingFailed(String)
    case invalidCSVFormat(String)
    case fileAccessDenied
    case invalidFileFormat
    case saveFailed(String)

    // ネットワーク関連
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let detail):
            return "データの読み込みに失敗しました: \(detail)"
        case .dataSaveFailed(let detail):
            return "データの保存に失敗しました: \(detail)"
        case .cardNotFound:
            return "カードが見つかりません"
        case .deckNotFound:
            return "単語帳が見つかりません"
        case .speechRecognitionNotAuthorized:
            return "音声認識が許可されていません"
        case .speechRecognitionFailed(let detail):
            return "音声認識に失敗しました: \(detail)"
        case .microphoneNotAvailable:
            return "マイクが使用できません"
        case .purchaseFailed(let detail):
            return "購入に失敗しました: \(detail)"
        case .purchaseNotVerified:
            return "購入の検証に失敗しました"
        case .productNotFound:
            return "商品が見つかりません"
        case .csvParsingFailed(let detail):
            return "CSVファイルの解析に失敗しました: \(detail)"
        case .invalidCSVFormat(let detail):
            return "CSVフォーマットエラー: \(detail)"
        case .fileAccessDenied:
            return "ファイルへのアクセスが拒否されました"
        case .invalidFileFormat:
            return "ファイル形式が無効です"
        case .saveFailed(let detail):
            return "保存に失敗しました: \(detail)"
        case .networkError(let detail):
            return "ネットワークエラー: \(detail)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "設定アプリから音声認識を許可してください"
        case .microphoneNotAvailable:
            return "設定アプリからマイクへのアクセスを許可してください"
        case .purchaseNotVerified:
            return "しばらく待ってから再度お試しください"
        case .networkError:
            return "インターネット接続を確認してください"
        default:
            return nil
        }
    }
}
