import AVFoundation

/// Text-to-Speech 管理クラス
/// 英単語の発音再生を担当
@MainActor
class TTSManager: NSObject, ObservableObject {
    static let shared = TTSManager()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var lastError: String?

    private override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // playbackカテゴリでサイレントモードでも再生可能に
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            lastError = "オーディオ設定エラー: \(error.localizedDescription)"
        }
    }

    /// 英単語を発音
    /// - Parameters:
    ///   - text: 発音するテキスト
    ///   - rate: 発音速度（デフォルト0.45）
    func speak(_ text: String, rate: Float = 0.45) {
        lastError = nil

        // 空文字チェック
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastError = "テキストが空です"
            return
        }

        // オーディオセッションを再設定（音声認識後の切り替え対応）
        // カテゴリが異なる場合のみ再設定（パフォーマンス最適化）
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback {
            do {
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to setup audio session for TTS: \(error)")
            }
        }

        // 既に再生中なら停止
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // 英語音声を取得（利用可能な最良の音声を選択）
        if let enhancedVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha") {
            utterance.voice = enhancedVoice
        } else if let premiumVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Samantha-premium") {
            utterance.voice = premiumVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1  // 少し遅延を入れて安定性向上

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// ゆっくり発音（学習用）
    func speakSlowly(_ text: String) {
        speak(text, rate: 0.35)
    }

    /// 複数の単語を順番に発音（活用形など）
    /// - Parameters:
    ///   - words: 発音する単語の配列
    ///   - interval: 単語間の間隔（秒）
    ///   - rate: 発音速度
    func speakSequence(_ words: [String], interval: TimeInterval = 0.8, rate: Float = 0.45) {
        // 空の単語を除外
        let validWords = words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validWords.isEmpty else { return }

        // 1単語だけなら通常の発音
        if validWords.count == 1 {
            speak(validWords[0], rate: rate)
            return
        }

        // 複数単語を順番に発音
        speakNextWord(words: validWords, index: 0, interval: interval, rate: rate)
    }

    /// 再帰的に次の単語を発音
    private func speakNextWord(words: [String], index: Int, interval: TimeInterval, rate: Float) {
        guard index < words.count else { return }

        speak(words[index], rate: rate)

        // 次の単語がある場合、間隔を空けて発音
        if index + 1 < words.count {
            // 現在の発音が終わってから次を発音するため、推定時間で遅延
            let estimatedDuration = Double(words[index].count) * 0.1 + 0.5
            let delay = estimatedDuration + interval

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.speakNextWord(words: words, index: index + 1, interval: interval, rate: rate)
            }
        }
    }

    /// 停止
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
