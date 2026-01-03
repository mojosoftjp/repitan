import Foundation
import Speech
import AVFoundation

/// 音声認識を管理するクラス
/// ユーザーの発音を認識し、英単語の回答として使用
@MainActor
class SpeechRecognizer: ObservableObject {

    // MARK: - Published Properties

    /// 認識中かどうか
    @Published var isRecognizing = false

    /// 認識されたテキスト
    @Published var recognizedText = ""

    /// エラーメッセージ
    @Published var errorMessage: String?

    /// 認識が利用可能か
    @Published var isAvailable = false

    /// 権限の状態
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// 認識完了時のコールバック
    private var onRecognitionComplete: ((String) -> Void)?

    /// 認識タイムアウト用タイマー
    private var timeoutTimer: Timer?

    /// 最大認識時間（秒）- テンポ良い応答のため短めに設定
    private let maxRecognitionDuration: TimeInterval = 3.0

    /// キャンセル処理中フラグ（エラー抑制用）
    private var isCancelling = false

    // MARK: - Initialization

    init() {
        // 英語（アメリカ）の音声認識器を使用
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        // 利用可能性を確認
        isAvailable = speechRecognizer?.isAvailable ?? false

        // 現在の権限状態を取得
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    /// 音声認識の権限をリクエスト
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    self.isAvailable = (status == .authorized) && (self.speechRecognizer?.isAvailable ?? false)
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    /// マイクの権限をリクエスト
    func requestMicrophoneAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// すべての必要な権限をリクエスト
    func requestAllPermissions() async -> Bool {
        let speechAuthorized = await requestAuthorization()
        guard speechAuthorized else {
            errorMessage = "音声認識が許可されていません"
            return false
        }

        let microphoneAuthorized = await requestMicrophoneAuthorization()
        guard microphoneAuthorized else {
            errorMessage = "マイクへのアクセスが許可されていません"
            return false
        }

        return true
    }

    // MARK: - Recognition

    /// 音声認識を開始
    /// - Parameter onComplete: 認識完了時のコールバック
    func startRecognition(onComplete: @escaping (String) -> Void) {
        guard !isRecognizing else { return }

        // 権限チェック
        guard authorizationStatus == .authorized else {
            errorMessage = "音声認識が許可されていません"
            return
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "音声認識が利用できません"
            return
        }

        onRecognitionComplete = onComplete
        recognizedText = ""
        errorMessage = nil

        do {
            try startAudioEngine()
            isRecognizing = true

            // タイムアウトタイマーを開始
            startTimeoutTimer()

        } catch {
            errorMessage = "音声認識の開始に失敗しました: \(error.localizedDescription)"
            stopRecognition()
        }
    }

    /// 音声認識を停止
    func stopRecognition() {
        // タイマーを停止
        timeoutTimer?.invalidate()
        timeoutTimer = nil

        // オーディオエンジンを停止
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // 認識リクエストを終了
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 認識タスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecognizing = false

        // オーディオセッションを解放（TTS用に切り替え可能にする）
        deactivateAudioSession()

        // 認識結果がある場合はコールバックを呼び出す
        if !recognizedText.isEmpty {
            onRecognitionComplete?(recognizedText)
        }
        onRecognitionComplete = nil
    }

    /// 状態をリセット（やり直し用）
    func reset() {
        // キャンセル処理中フラグを立てる（エラーを抑制）
        isCancelling = true

        // タイマーを停止
        timeoutTimer?.invalidate()
        timeoutTimer = nil

        // オーディオエンジンを停止
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // 認識リクエストを終了
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 認識タスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecognizing = false

        // オーディオセッションを解放
        deactivateAudioSession()

        // コールバックはクリアしない（やり直しで再利用するため）
        recognizedText = ""
        errorMessage = nil

        // フラグをリセット（少し遅延させてエラーコールバックを無視）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isCancelling = false
        }
    }

    /// オーディオセッションを解放（バックグラウンドで実行）
    private func deactivateAudioSession() {
        DispatchQueue.global(qos: .utility).async {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
    }

    // MARK: - Private Methods

    /// オーディオエンジンを開始
    private func startAudioEngine() throws {
        // 既存のタスクをキャンセル
        recognitionTask?.cancel()
        recognitionTask = nil

        // オーディオセッションを設定
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 認識リクエストを作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw AppError.speechRecognitionFailed("認識リクエストの作成に失敗しました")
        }

        // 部分的な結果も取得
        recognitionRequest.shouldReportPartialResults = true

        // オンデバイス認識を優先（プライバシー重視）
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        // 認識タスクを開始
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let result = result {
                    // 認識結果を更新
                    self.recognizedText = result.bestTranscription.formattedString

                    // 最終結果の場合は停止
                    if result.isFinal {
                        self.stopRecognition()
                    }
                }

                if let error = error {
                    // キャンセル処理中はエラーを無視
                    guard !self.isCancelling else { return }

                    // ユーザーによるキャンセルまたはリクエストキャンセルは無視
                    let nsError = error as NSError
                    // kAFAssistantErrorDomain code 216: ユーザーキャンセル
                    // kAFAssistantErrorDomain code 1110: リクエストキャンセル
                    // kAFAssistantErrorDomain code 1101: 認識タスクキャンセル
                    let ignoredCodes = [216, 1110, 1101]
                    if nsError.domain == "kAFAssistantErrorDomain" && ignoredCodes.contains(nsError.code) {
                        // キャンセル系エラーは無視
                    } else {
                        self.errorMessage = "認識エラー: \(error.localizedDescription)"
                    }
                    self.stopRecognition()
                }
            }
        }

        // オーディオ入力を設定
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // オーディオエンジンを開始
        audioEngine.prepare()
        try audioEngine.start()
    }

    /// タイムアウトタイマーを開始
    private func startTimeoutTimer() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: maxRecognitionDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopRecognition()
            }
        }
    }

    // MARK: - Answer Checking

    /// 認識結果が正解かどうかをチェック
    /// - Parameters:
    ///   - recognized: 認識されたテキスト
    ///   - expected: 期待される正解
    /// - Returns: 正解かどうか
    static func checkAnswer(recognized: String, expected: String) -> Bool {
        let normalizedRecognized = normalize(recognized)
        let normalizedExpected = normalize(expected)

        // 完全一致
        if normalizedRecognized == normalizedExpected {
            return true
        }

        // 類似度チェック（80%以上で正解とみなす）
        let similarity = calculateSimilarity(normalizedRecognized, normalizedExpected)
        return similarity >= 0.8
    }

    /// テキストを正規化
    private static func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "'")
            .replacingOccurrences(of: "'", with: "'")
    }

    /// 2つの文字列の類似度を計算（レーベンシュタイン距離ベース）
    private static func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let len1 = s1.count
        let len2 = s2.count

        if len1 == 0 && len2 == 0 { return 1.0 }
        if len1 == 0 || len2 == 0 { return 0.0 }

        let distance = levenshteinDistance(s1, s2)
        let maxLen = max(len1, len2)

        return 1.0 - (Double(distance) / Double(maxLen))
    }

    /// レーベンシュタイン距離を計算
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let len1 = s1Array.count
        let len2 = s2Array.count

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: len2 + 1), count: len1 + 1)

        for i in 0...len1 {
            matrix[i][0] = i
        }
        for j in 0...len2 {
            matrix[0][j] = j
        }

        for i in 1...len1 {
            for j in 1...len2 {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // 削除
                    matrix[i][j - 1] + 1,      // 挿入
                    matrix[i - 1][j - 1] + cost // 置換
                )
            }
        }

        return matrix[len1][len2]
    }
}
