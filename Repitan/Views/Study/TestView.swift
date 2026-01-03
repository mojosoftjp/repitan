import SwiftUI
import SwiftData

/// テスト画面（学習実行画面）
struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Query private var allCardsInDB: [Card]

    let cards: [Card]
    let sessionType: SessionType

    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var session: StudySession?
    @State private var showCompleteView = false
    @State private var startTime = Date()

    // 音声認識関連
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showSpeechResult = false
    @State private var speechResult: SpeechResultType?
    @State private var isRequestingPermission = false

    // タイピング入力関連
    @State private var typingInput = ""
    @State private var typingResult: TypingResultType?
    @FocusState private var isTypingFocused: Bool
    @State private var typingStartTime: Date?

    // 複合回答モード（活用形）関連
    @State private var presentFormInput = ""
    @State private var pastFormInput = ""
    @State private var pastParticipleInput = ""
    @State private var conjugationResult: ConjugationResultType?
    @FocusState private var presentFormFocused: Bool
    @FocusState private var pastFormFocused: Bool
    @FocusState private var pastParticipleFocused: Bool

    enum SpeechResultType {
        case correct
        case incorrect(recognized: String)
    }

    enum TypingResultType {
        case correct(responseTime: TimeInterval)
        case incorrect(typed: String)
    }

    /// 活用形回答の結果
    struct ConjugationResultType {
        var presentCorrect: Bool
        var pastCorrect: Bool?
        var pastParticipleCorrect: Bool?

        // ユーザーの入力値を保存
        var presentInput: String
        var pastInput: String?
        var pastParticipleInput: String?

        var isAllCorrect: Bool {
            let pastOk = pastCorrect ?? true
            let ppOk = pastParticipleCorrect ?? true
            return presentCorrect && pastOk && ppOk
        }
    }

    /// 現在の回答方法
    private var currentAnswerMethod: AnswerMethod {
        userSettings?.preferredAnswerMethod ?? .typing
    }

    /// 音声認識モードが有効か（設定で明示的にONの場合のみ）
    private var isSpeechModeEnabled: Bool {
        userSettings?.useSpeechRecognition ?? false
    }

    /// 自動発音再生が有効か
    private var isAutoPlayEnabled: Bool {
        userSettings?.autoPlayPronunciation ?? true
    }

    /// 触覚フィードバックが有効か
    private var isHapticEnabled: Bool {
        userSettings?.hapticEnabled ?? true
    }

    private var userSettings: UserSettings? {
        settings.first
    }

    private var currentCard: Card? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    private var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    /// 現在のカードが複合回答モード（活用形出題）を使用するか
    private var requiresConjugationMode: Bool {
        guard let card = currentCard,
              let deck = card.deck else { return false }

        let mode = deck.conjugationMode

        switch mode {
        case .presentOnly:
            return false
        case .presentAndPast:
            // 過去形を持つカードのみ複合モード
            return card.pastTense != nil
        case .allForms:
            // 過去形または過去分詞を持つカードのみ複合モード
            return card.pastTense != nil || card.pastParticiple != nil
        }
    }

    /// 現在のカードで要求する活用形モード
    private var currentConjugationMode: ConjugationMode {
        currentCard?.deck?.conjugationMode ?? .presentOnly
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpBackground.ignoresSafeArea()

                if let card = currentCard {
                    VStack(spacing: 0) {
                        // プログレスバー
                        ProgressBar(progress: progress, current: currentIndex + 1, total: cards.count)

                        Spacer()

                        // カード表示
                        CardDisplayView(card: card, showAnswer: showAnswer)

                        Spacer()

                        // 回答エリア
                        if showAnswer {
                            // 複合回答モードの結果表示
                            if let result = conjugationResult {
                                ConjugationResultView(
                                    result: result,
                                    card: card,
                                    mode: currentConjugationMode,
                                    allCards: allCardsInDB
                                )
                                .padding(.bottom, 16)
                            }

                            // 音声認識結果表示
                            if showSpeechResult, let result = speechResult {
                                SpeechResultView(result: result, expectedWord: card.english)
                                    .padding(.bottom, 16)
                            }

                            // タイピング結果表示
                            if let result = typingResult {
                                TypingResultView(result: result, expectedWord: card.english, allCards: allCardsInDB)
                                    .padding(.bottom, 16)
                            }

                            // 結果がある場合は「次へ」ボタン、ない場合は評価ボタン
                            if conjugationResult != nil || speechResult != nil || typingResult != nil {
                                // タイピング/音声/複合回答モードでは「次へ」ボタンを表示
                                Button {
                                    moveToNextCard()
                                } label: {
                                    Text("次へ")
                                }
                                .buttonStyle(RPPrimaryButtonStyle())
                                .padding(.horizontal, 32)
                                .padding(.bottom, 32)
                            } else {
                                // 結果がない場合は評価ボタンを表示（自己申告モード）
                                RatingButtonsView(
                                    card: card,
                                    userSettings: userSettings
                                ) { rating in
                                    handleRating(rating)
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                // 複合回答モードの場合
                                if requiresConjugationMode {
                                    ConjugationInputView(
                                        card: card,
                                        mode: currentConjugationMode,
                                        presentInput: $presentFormInput,
                                        pastInput: $pastFormInput,
                                        pastParticipleInput: $pastParticipleInput,
                                        presentFocused: $presentFormFocused,
                                        pastFocused: $pastFormFocused,
                                        pastParticipleFocused: $pastParticipleFocused
                                    ) { result in
                                        handleConjugationResult(result, for: card)
                                    }
                                } else {
                                    // 通常モード：回答方法に応じたUI
                                    switch currentAnswerMethod {
                                    case .typing:
                                        // タイピング入力
                                        TypingInputView(
                                            input: $typingInput,
                                            isFocused: $isTypingFocused,
                                            expectedWord: card.english,
                                            startTime: typingStartTime
                                        ) { result in
                                            handleTypingResult(result, for: card)
                                        }

                                    case .voice:
                                        // 音声入力
                                        SpeechInputButton(
                                            speechRecognizer: speechRecognizer,
                                            isRequestingPermission: $isRequestingPermission,
                                            expectedWord: card.english
                                        ) { result in
                                            handleSpeechResult(result, for: card)
                                        }

                                    case .selfReport:
                                        // 自己申告モード：追加の音声認識ボタン（設定で有効な場合）
                                        if isSpeechModeEnabled {
                                            SpeechInputButton(
                                                speechRecognizer: speechRecognizer,
                                                isRequestingPermission: $isRequestingPermission,
                                                expectedWord: card.english
                                            ) { result in
                                                handleSpeechResult(result, for: card)
                                            }
                                        }
                                    }
                                }

                                // 答えを見るボタン（常に表示）
                                Button {
                                    revealAnswer()
                                } label: {
                                    Text("答えを見る")
                                }
                                .buttonStyle(RPPrimaryButtonStyle())
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showExitConfirmation()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.rpTextPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex + 1) / \(cards.count)")
                        .font(.rpBodyBold)
                        .foregroundColor(.rpTextPrimary)
                }
            }
            .onAppear {
                startSession()
                // タイピング開始時刻を初期化
                typingStartTime = Date()
            }
            .onChange(of: showCompleteView) { _, newValue in
                if newValue {
                    // fullScreenCover表示時にキーボードを確実に閉じる
                    isTypingFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    for scene in UIApplication.shared.connectedScenes {
                        if let windowScene = scene as? UIWindowScene {
                            for window in windowScene.windows {
                                window.endEditing(true)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCompleteView) {
                if let session = session {
                    SessionCompleteView(session: session, dismissTestView: dismiss)
                }
            }
        }
    }

    private func startSession() {
        session = StudySession(sessionType: sessionType)
        if let session = session {
            modelContext.insert(session)
        }
        startTime = Date()
    }

    private func handleRating(_ rating: SM2Algorithm.SimpleRating) {
        guard let card = currentCard, let session = session else { return }

        // 新規カードかどうかを先に記録（SM2適用後はstatusが変わるため）
        let wasNewCard = card.status == .new

        // 触覚フィードバック
        if isHapticEnabled {
            switch rating {
            case .easy:
                HapticManager.shared.success()
            case .hard:
                HapticManager.shared.mediumTap()
            case .again:
                HapticManager.shared.error()
            }
        }

        // SM-2アルゴリズムで計算
        let result = SM2Algorithm.calculate(card: card, rating: rating, settings: userSettings)
        SM2Algorithm.apply(result: result, to: card)

        // 通知はセッション完了時にまとめてスケジュール

        // 復習履歴を記録
        let history = ReviewHistory(
            quality: rating.quality,
            answerMethod: .selfReport,
            intervalAtReview: card.interval,
            easeFactorAtReview: card.easeFactor
        )
        history.card = card
        history.session = session
        modelContext.insert(history)

        // セッション統計を更新
        session.recordAnswer(isCorrect: rating.isCorrect)

        // DailyStatsを更新
        let statsManager = DailyStatsManager(modelContext: modelContext)
        statsManager.recordReview(isNew: wasNewCard, isCorrect: rating.isCorrect)

        // 次のカードへ
        moveToNextCard()
    }

    private func moveToNextCard() {
        // 音声認識状態をリセット
        resetSpeechState()

        // 触覚フィードバック（カード切り替え）
        if isHapticEnabled {
            HapticManager.shared.selectionChanged()
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = false
        }

        if currentIndex < cards.count - 1 {
            currentIndex += 1

            // タイピング開始時刻をリセット
            typingStartTime = Date()

            // タイピングモードの場合、次のカードでキーボードを再表示
            if currentAnswerMethod == .typing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTypingFocused = true
                }
            }
        } else {
            // セッション完了
            completeSession()
        }
    }

    private func completeSession() {
        guard let session = session else { return }
        session.complete()

        // キーボードを確実に閉じる（複数の方法を併用）
        isTypingFocused = false

        // 方法1: sendAction
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // 方法2: 全てのウィンドウでendEditing
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.endEditing(true)
                }
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save session: \(error)")
        }

        // セッション完了時に学習中カードの通知をまとめてスケジュール
        scheduleSessionNotifications()

        // キーボードが閉じるのを十分に待ってから完了画面を表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCompleteView = true
        }
    }

    /// セッション完了時に学習中カードの通知をまとめてスケジュール
    private func scheduleSessionNotifications() {
        // このセッションで学習したカードのうち、学習中（learning/relearning）のものを抽出
        let learningCards = cards.filter { card in
            card.status == .learning || card.status == .relearning
        }

        guard !learningCards.isEmpty else { return }

        // セッション完了時点から各ステップの時間後にlearningDueDateを設定
        let learningSteps = userSettings?.learningSteps ?? [3, 20]
        let relearningSteps = userSettings?.relearningSteps ?? [20]
        let sessionEndTime = Date()

        for card in learningCards {
            // カードの学習ステップに応じた待機時間を計算
            let steps = (card.status == .relearning) ? relearningSteps : learningSteps
            let stepIndex = max(0, card.learningStep)
            let minutesToWait: Int

            if stepIndex >= steps.count {
                // ステップ範囲外の場合は最初のステップを使用
                minutesToWait = steps.first ?? 3
            } else {
                minutesToWait = steps[stepIndex]
            }

            // セッション完了時点から計算した時間に更新
            card.learningDueDate = Calendar.current.date(
                byAdding: .minute,
                value: minutesToWait,
                to: sessionEndTime
            ) ?? sessionEndTime.addingTimeInterval(TimeInterval(minutesToWait * 60))
        }

        // 通知が有効な場合のみスケジュール
        guard userSettings?.notificationEnabled ?? false else { return }

        // 最も早く復習可能になるカードの時刻を取得
        guard let earliestDueDate = learningCards.compactMap({ $0.learningDueDate }).min() else {
            return
        }

        // まとめて1つの通知をスケジュール（最も早い復習時刻で）
        let cardCount = learningCards.count
        NotificationManager.shared.scheduleSessionLearningNotification(
            cardCount: cardCount,
            dueDate: earliestDueDate
        )
    }

    private func showExitConfirmation() {
        // 簡易実装：直接閉じる
        dismiss()
    }

    /// 答えを表示
    private func revealAnswer() {
        guard let card = currentCard else { return }

        // 触覚フィードバック
        if isHapticEnabled {
            HapticManager.shared.lightTap()
        }

        // 自己判定モード以外は自動判定を行う
        if currentAnswerMethod != .selfReport {
            if requiresConjugationMode {
                // 活用形モードの場合は入力内容に基づいて正誤判定を行う
                // 現在の入力で判定（空欄は不正解扱い）
                let trimmedPresent = normalizeInputString(presentFormInput)
                let expectedPresent = normalizeInputString(card.english)
                let presentCorrect = trimmedPresent == expectedPresent

                // デバッグログ
                print("=== revealAnswer Conjugation Check ===")
                print("Present: '\(trimmedPresent)' vs '\(expectedPresent)' -> \(presentCorrect)")

                var pastCorrect: Bool? = nil
                let mode = card.deck?.conjugationMode ?? .presentOnly
                let requiresPast = (mode == .presentAndPast || mode == .allForms) && card.pastTense != nil

                if requiresPast, let expected = card.pastTense {
                    let trimmedPast = normalizeInputString(pastFormInput)
                    let expectedPast = normalizeInputString(expected)
                    pastCorrect = trimmedPast == expectedPast
                    print("Past: '\(trimmedPast)' vs '\(expectedPast)' -> \(pastCorrect ?? false)")
                }

                var ppCorrect: Bool? = nil
                let requiresPastParticiple = mode == .allForms && card.pastParticiple != nil

                if requiresPastParticiple, let expected = card.pastParticiple {
                    let trimmedPP = normalizeInputString(pastParticipleInput)
                    let expectedPP = normalizeInputString(expected)
                    ppCorrect = trimmedPP == expectedPP
                    print("PP: '\(trimmedPP)' vs '\(expectedPP)' -> \(ppCorrect ?? false)")
                }
                print("======================================")

                let result = ConjugationResultType(
                    presentCorrect: presentCorrect,
                    pastCorrect: pastCorrect,
                    pastParticipleCorrect: ppCorrect,
                    presentInput: presentFormInput,
                    pastInput: requiresPast ? pastFormInput : nil,
                    pastParticipleInput: requiresPastParticiple ? pastParticipleInput : nil
                )

                conjugationResult = result

                // 自動評価を記録（全て正解→easy, 不正解→again）
                let rating: SM2Algorithm.SimpleRating = result.isAllCorrect ? .easy : .again
                recordAutoRating(for: card, rating: rating, answerMethod: .typing)

                // 触覚フィードバック（正誤に応じて）
                if isHapticEnabled {
                    if result.isAllCorrect {
                        HapticManager.shared.success()
                    } else {
                        HapticManager.shared.error()
                    }
                }
            } else {
                // タイピングモード（活用形なし）の場合
                let trimmedInput = normalizeInputString(typingInput)
                let expected = normalizeInputString(card.english)
                let isCorrect = trimmedInput == expected

                print("=== revealAnswer Typing Check ===")
                print("Input: '\(trimmedInput)' vs '\(expected)' -> \(isCorrect)")
                print("=================================")

                // 回答時間を計算
                let responseTime: TimeInterval
                if let start = typingStartTime {
                    responseTime = Date().timeIntervalSince(start)
                } else {
                    responseTime = 0
                }

                let result: TypingResultType = isCorrect ? .correct(responseTime: responseTime) : .incorrect(typed: typingInput)
                typingResult = result
                isTypingFocused = false

                // 回答時間に基づいて評価を決定
                let rating: SM2Algorithm.SimpleRating
                if isCorrect {
                    rating = responseTime < 3.0 ? .easy : .hard
                } else {
                    rating = .again
                }

                // 自動評価を記録
                recordAutoRating(for: card, rating: rating, answerMethod: .typing)

                // 触覚フィードバック（正誤に応じて）
                if isHapticEnabled {
                    if isCorrect {
                        HapticManager.shared.success()
                    } else {
                        HapticManager.shared.error()
                    }
                }
            }
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = true
        }

        // 自動発音再生（活用形モードに応じて複数形を発音）
        if isAutoPlayEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 発音する単語リストを構築
                var wordsToSpeak: [String] = [card.english]

                // 活用形モードに応じて過去形・過去分詞を追加
                let mode = card.deck?.conjugationMode ?? .presentOnly

                switch mode {
                case .presentOnly:
                    // 原形のみ
                    break
                case .presentAndPast:
                    // 原形 + 過去形
                    if let pastTense = card.pastTense {
                        wordsToSpeak.append(pastTense)
                    }
                case .allForms:
                    // 原形 + 過去形 + 過去分詞
                    if let pastTense = card.pastTense {
                        wordsToSpeak.append(pastTense)
                    }
                    if let pastParticiple = card.pastParticiple {
                        wordsToSpeak.append(pastParticiple)
                    }
                }

                TTSManager.shared.speakSequence(wordsToSpeak)
            }
        }
    }

    /// 音声認識結果を処理
    private func handleSpeechResult(_ result: SpeechResultType, for card: Card) {
        speechResult = result
        showSpeechResult = true

        // 自動評価を記録（正解→easy, 不正解→again）
        let rating: SM2Algorithm.SimpleRating
        switch result {
        case .correct:
            rating = .easy
        case .incorrect:
            rating = .again
        }
        recordAutoRating(for: card, rating: rating, answerMethod: .voice)

        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = true
        }

        // 自動発音再生
        if isAutoPlayEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                TTSManager.shared.speak(card.english)
            }
        }
    }

    /// タイピング結果を処理
    private func handleTypingResult(_ result: TypingResultType, for card: Card) {
        typingResult = result
        isTypingFocused = false

        // 自動評価を記録
        let isCorrect: Bool
        let responseTime: TimeInterval

        switch result {
        case .correct(let time):
            isCorrect = true
            responseTime = time
        case .incorrect:
            isCorrect = false
            responseTime = 0
        }

        // 回答時間に基づいて評価を決定
        // 3秒未満: 即答 → easy（完璧！）
        // 3秒以上: 少し考えた → hard（少し考えた）
        let rating: SM2Algorithm.SimpleRating
        if isCorrect {
            rating = responseTime < 3.0 ? .easy : .hard
            print("=== Typing Auto-Rating ===")
            print("Response time: \(String(format: "%.1f", responseTime))s")
            print("Rating: \(rating == .easy ? "Easy (完璧！)" : "Hard (少し考えた)")")
            print("========================")
        } else {
            rating = .again
        }

        recordAutoRating(for: card, rating: rating, answerMethod: .typing)

        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = true
        }

        // 自動発音再生
        if isAutoPlayEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                TTSManager.shared.speak(card.english)
            }
        }
    }

    /// 自動評価を記録（タイピング/音声モード用）
    private func recordAutoRating(for card: Card, rating: SM2Algorithm.SimpleRating, answerMethod: AnswerMethod) {
        guard let session = session else { return }

        // 新規カードかどうかを先に記録（SM2適用後はstatusが変わるため）
        let wasNewCard = card.status == .new

        // 正解判定
        let isCorrect = rating.isCorrect

        // 触覚フィードバック
        if isHapticEnabled {
            if isCorrect {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        }

        // SM-2アルゴリズムで計算
        let result = SM2Algorithm.calculate(card: card, rating: rating, settings: userSettings)
        SM2Algorithm.apply(result: result, to: card)

        // 通知はセッション完了時にまとめてスケジュール

        // 復習履歴を記録
        let history = ReviewHistory(
            quality: rating.quality,
            answerMethod: answerMethod,
            intervalAtReview: card.interval,
            easeFactorAtReview: card.easeFactor
        )
        history.card = card
        history.session = session
        modelContext.insert(history)

        // セッション統計を更新
        session.recordAnswer(isCorrect: isCorrect)

        // DailyStatsを更新
        let statsManager = DailyStatsManager(modelContext: modelContext)
        statsManager.recordReview(isNew: wasNewCard, isCorrect: isCorrect)
    }

    /// 入力文字列を正規化（不可視文字、特殊スペース等を除去）
    private func normalizeInputString(_ input: String) -> String {
        var result = input
        // 通常のトリム
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        // 小文字化
        result = result.lowercased()
        // ゼロ幅文字を除去
        result = result.replacingOccurrences(of: "\u{200B}", with: "") // Zero Width Space
        result = result.replacingOccurrences(of: "\u{200C}", with: "") // Zero Width Non-Joiner
        result = result.replacingOccurrences(of: "\u{200D}", with: "") // Zero Width Joiner
        result = result.replacingOccurrences(of: "\u{FEFF}", with: "") // BOM
        // 特殊スペースを通常スペースに変換後除去
        result = result.replacingOccurrences(of: "\u{00A0}", with: " ") // Non-Breaking Space
        result = result.replacingOccurrences(of: "\u{2003}", with: " ") // Em Space
        result = result.replacingOccurrences(of: "\u{2002}", with: " ") // En Space
        result = result.trimmingCharacters(in: .whitespaces)
        return result
    }

    /// 次のカードへ移動時に音声認識状態をリセット
    private func resetSpeechState() {
        showSpeechResult = false
        speechResult = nil
        typingInput = ""
        typingResult = nil
        // 複合回答モードの状態もリセット
        presentFormInput = ""
        pastFormInput = ""
        pastParticipleInput = ""
        conjugationResult = nil
    }

    /// 複合回答モードの結果を処理
    private func handleConjugationResult(_ result: ConjugationResultType, for card: Card) {
        conjugationResult = result

        // 自動評価を記録（全て正解→easy, 不正解→again）
        let rating: SM2Algorithm.SimpleRating = result.isAllCorrect ? .easy : .again
        recordAutoRating(for: card, rating: rating, answerMethod: .typing)

        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = true
        }

        // 自動発音再生（活用形モードに応じて複数形を発音）
        if isAutoPlayEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 発音する単語リストを構築
                var wordsToSpeak: [String] = [card.english]

                // 活用形モードに応じて過去形・過去分詞を追加
                let mode = card.deck?.conjugationMode ?? .presentOnly

                switch mode {
                case .presentOnly:
                    // 原形のみ
                    break
                case .presentAndPast:
                    // 原形 + 過去形
                    if let pastTense = card.pastTense {
                        wordsToSpeak.append(pastTense)
                    }
                case .allForms:
                    // 原形 + 過去形 + 過去分詞
                    if let pastTense = card.pastTense {
                        wordsToSpeak.append(pastTense)
                    }
                    if let pastParticiple = card.pastParticiple {
                        wordsToSpeak.append(pastParticiple)
                    }
                }

                TTSManager.shared.speakSequence(wordsToSpeak)
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let progress: Double
    let current: Int
    let total: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.rpTextSecondary.opacity(0.2))

                Rectangle()
                    .fill(Color.rpPrimary)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Card Display View

struct CardDisplayView: View {
    let card: Card
    let showAnswer: Bool

    /// 品詞に応じた色を返す
    private func partOfSpeechColor(_ pos: String) -> Color {
        switch pos {
        case "名詞": return .blue
        case "動詞": return .green
        case "形容詞": return .orange
        case "副詞": return .purple
        case "前置詞": return .pink
        case "接続詞": return .cyan
        case "代名詞": return .indigo
        case "助動詞": return .teal
        case "感嘆詞": return .mint
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // 問題（日本語）
            VStack(spacing: 8) {
                Text(card.japanese)
                    .font(.rpWordJapanese)
                    .foregroundColor(.rpTextPrimary)
                    .multilineTextAlignment(.center)

                // 品詞表示
                if let partOfSpeech = card.partOfSpeech, !partOfSpeech.isEmpty {
                    Text(partOfSpeech)
                        .font(.rpCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(partOfSpeechColor(partOfSpeech))
                        .cornerRadius(12)
                }
            }

            if showAnswer {
                Divider()
                    .padding(.horizontal, 48)

                // 答え（英語）
                VStack(spacing: 8) {
                    Text(card.english)
                        .font(.rpWordEnglish)
                        .foregroundColor(.rpPrimary)

                    if let phonetic = card.phonetic {
                        Text(phonetic)
                            .font(.rpPhonetic)
                            .foregroundColor(.rpTextSecondary)
                    }

                    // 発音ボタン
                    Button {
                        TTSManager.shared.speak(card.english)
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("発音を聞く")
                        }
                        .font(.rpSubheadline)
                        .foregroundColor(.rpPrimary)
                    }
                    .padding(.top, 8)

                    // 不規則動詞の活用形（過去形・過去分詞がある場合のみ表示）
                    if card.hasIrregularForms {
                        IrregularVerbFormsView(card: card)
                            .padding(.top, 12)
                    }

                    // 例文
                    if let example = card.example {
                        VStack(spacing: 4) {
                            Text(example)
                                .font(.rpBody)
                                .foregroundColor(.rpTextPrimary)
                                .italic()

                            if let exampleJapanese = card.exampleJapanese {
                                Text(exampleJapanese)
                                    .font(.rpSubheadline)
                                    .foregroundColor(.rpTextSecondary)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                    }
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Irregular Verb Forms View

/// 不規則動詞の活用形表示
struct IrregularVerbFormsView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // 過去形
                if let pastTense = card.pastTense {
                    VerbFormCell(
                        label: "過去形",
                        word: pastTense,
                        phonetic: card.pastTensePhonetic
                    )
                }

                // 過去分詞
                if let pastParticiple = card.pastParticiple {
                    VerbFormCell(
                        label: "過去分詞",
                        word: pastParticiple,
                        phonetic: card.pastParticiplePhonetic
                    )
                }
            }
        }
        .padding(12)
        .background(Color.rpCardBackground)
        .cornerRadius(8)
    }
}

/// 動詞活用形の個別セル
struct VerbFormCell: View {
    let label: String
    let word: String
    let phonetic: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.rpCaption)
                .foregroundColor(.rpTextSecondary)

            Text(word)
                .font(.rpBodyBold)
                .foregroundColor(.rpPrimary)

            if let phonetic = phonetic {
                Text(phonetic)
                    .font(.rpCaption2)
                    .foregroundColor(.rpTextSecondary)
            }

            // 発音ボタン
            Button {
                TTSManager.shared.speak(word)
            } label: {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.rpPrimary)
            }
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Rating Buttons View

struct RatingButtonsView: View {
    let card: Card
    let userSettings: UserSettings?
    let onRate: (SM2Algorithm.SimpleRating) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("どのくらいできた？")
                .font(.rpSubheadline)
                .foregroundColor(.rpTextSecondary)

            HStack(spacing: 12) {
                // 全然ダメ
                RatingButton(
                    rating: .again,
                    nextReviewText: SM2Algorithm.nextReviewText(for: card, rating: .again, settings: userSettings)
                ) {
                    onRate(.again)
                }

                // 少し考えた
                RatingButton(
                    rating: .hard,
                    nextReviewText: SM2Algorithm.nextReviewText(for: card, rating: .hard, settings: userSettings)
                ) {
                    onRate(.hard)
                }

                // 完璧！
                RatingButton(
                    rating: .easy,
                    nextReviewText: SM2Algorithm.nextReviewText(for: card, rating: .easy, settings: userSettings)
                ) {
                    onRate(.easy)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Rating Button

struct RatingButton: View {
    let rating: SM2Algorithm.SimpleRating
    let nextReviewText: String
    let action: () -> Void

    private var backgroundColor: Color {
        switch rating {
        case .again: return .rpAgain
        case .hard: return .rpHard
        case .easy: return .rpEasy
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(rating.displayEmoji)
                    .font(.system(size: 28))

                Text(rating.displayText)
                    .font(.rpButtonSmall)
                    .foregroundColor(.white)

                Text(nextReviewText)
                    .font(.rpCaption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Speech Input Button

struct SpeechInputButton: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @Binding var isRequestingPermission: Bool
    let expectedWord: String
    let onResult: (TestView.SpeechResultType) -> Void

    /// 確認待ち状態（認識結果を表示して確認ボタン待ち）
    @State private var pendingConfirmation = false
    /// 確認待ち中の認識結果
    @State private var pendingRecognizedText = ""

    var body: some View {
        VStack(spacing: 12) {
            if pendingConfirmation {
                // 確認待ち状態：認識結果と確認ボタンを表示
                SpeechConfirmationView(
                    recognizedText: pendingRecognizedText,
                    expectedWord: expectedWord,
                    onConfirm: {
                        confirmResult()
                    },
                    onRetry: {
                        retryRecognition()
                    }
                )
            } else {
                // 通常状態：マイクボタン
                Button {
                    handleSpeechButtonTap()
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(speechRecognizer.isRecognizing ? Color.rpError : Color.rpPrimary)
                                .frame(width: 64, height: 64)

                            if speechRecognizer.isRecognizing {
                                // 録音中のアニメーション
                                Circle()
                                    .stroke(Color.rpError.opacity(0.5), lineWidth: 3)
                                    .frame(width: 72, height: 72)
                                    .scaleEffect(speechRecognizer.isRecognizing ? 1.2 : 1.0)
                                    .opacity(speechRecognizer.isRecognizing ? 0.5 : 1.0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechRecognizer.isRecognizing)
                            }

                            Image(systemName: speechRecognizer.isRecognizing ? "stop.fill" : "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }

                        Text(speechRecognizer.isRecognizing ? "タップして停止" : "発音してみる")
                            .font(.rpSubheadline)
                            .foregroundColor(.rpTextSecondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRequestingPermission)

                // 認識中のテキスト表示
                if speechRecognizer.isRecognizing && !speechRecognizer.recognizedText.isEmpty {
                    Text(speechRecognizer.recognizedText)
                        .font(.rpBody)
                        .foregroundColor(.rpTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.rpCardBackground)
                        .cornerRadius(8)
                }

                // エラーメッセージ
                if let error = speechRecognizer.errorMessage {
                    Text(error)
                        .font(.rpCaption)
                        .foregroundColor(.rpError)
                }
            }
        }
    }

    private func handleSpeechButtonTap() {
        if speechRecognizer.isRecognizing {
            speechRecognizer.stopRecognition()
            showConfirmation()
        } else {
            startRecognition()
        }
    }

    private func startRecognition() {
        // 権限チェック
        if speechRecognizer.authorizationStatus != .authorized {
            isRequestingPermission = true
            Task {
                let granted = await speechRecognizer.requestAllPermissions()
                isRequestingPermission = false
                if granted {
                    beginRecognition()
                }
            }
        } else {
            beginRecognition()
        }
    }

    private func beginRecognition() {
        speechRecognizer.startRecognition { recognizedText in
            showConfirmation()
        }
    }

    /// 確認画面を表示
    private func showConfirmation() {
        let recognized = speechRecognizer.recognizedText
        guard !recognized.isEmpty else { return }

        pendingRecognizedText = recognized
        // アニメーション高速化
        withAnimation(.easeOut(duration: 0.1)) {
            pendingConfirmation = true
        }
        // 触覚フィードバック
        HapticManager.shared.lightTap()
    }

    /// 認識結果を確定して判定
    private func confirmResult() {
        let isCorrect = SpeechRecognizer.checkAnswer(recognized: pendingRecognizedText, expected: expectedWord)
        let recognizedTextForResult = pendingRecognizedText

        // 触覚フィードバック（即時）
        if isCorrect {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }

        // 確認状態をリセット
        pendingConfirmation = false
        pendingRecognizedText = ""

        if isCorrect {
            onResult(.correct)
        } else {
            onResult(.incorrect(recognized: recognizedTextForResult.isEmpty ? speechRecognizer.recognizedText : recognizedTextForResult))
        }
    }

    /// やり直し
    private func retryRecognition() {
        // 触覚フィードバック
        HapticManager.shared.lightTap()

        pendingConfirmation = false
        pendingRecognizedText = ""
        speechRecognizer.reset()

        // 遅延を最小化して素早く再認識開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            beginRecognition()
        }
    }
}

// MARK: - Speech Confirmation View

/// 音声認識結果の確認UI
struct SpeechConfirmationView: View {
    let recognizedText: String
    let expectedWord: String
    let onConfirm: () -> Void
    let onRetry: () -> Void

    /// 認識結果が正解と一致しそうかの予測
    private var isPredictedCorrect: Bool {
        SpeechRecognizer.checkAnswer(recognized: recognizedText, expected: expectedWord)
    }

    var body: some View {
        VStack(spacing: 16) {
            // 認識結果表示
            VStack(spacing: 8) {
                Text("認識結果")
                    .font(.rpCaption)
                    .foregroundColor(.rpTextSecondary)

                Text(recognizedText)
                    .font(.rpHeadline)
                    .foregroundColor(isPredictedCorrect ? .rpSuccess : .rpTextPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPredictedCorrect ? Color.rpSuccess.opacity(0.1) : Color.rpCardBackground)
                    )

                if isPredictedCorrect {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.rpSuccess)
                        Text("正解と一致しています")
                            .font(.rpCaption)
                            .foregroundColor(.rpSuccess)
                    }
                }
            }

            // ボタン
            HStack(spacing: 12) {
                // やり直しボタン
                Button {
                    onRetry()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("やり直し")
                    }
                    .font(.rpButton)
                    .foregroundColor(.rpTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rpCardBackground)
                    .cornerRadius(12)
                }

                // 確定ボタン
                Button {
                    onConfirm()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("これで判定")
                    }
                    .font(.rpButton)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rpPrimary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.rpBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Speech Result View

struct SpeechResultView: View {
    let result: TestView.SpeechResultType
    let expectedWord: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isCorrect ? .rpSuccess : .rpError)

            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? "正解！" : "惜しい！")
                    .font(.rpHeadline)
                    .foregroundColor(isCorrect ? .rpSuccess : .rpError)

                if case .incorrect(let recognized) = result {
                    Text("あなたの発音: \(recognized)")
                        .font(.rpCaption)
                        .foregroundColor(.rpTextSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.rpSuccess.opacity(0.1) : Color.rpError.opacity(0.1))
        )
        .padding(.horizontal, 32)
    }

    private var isCorrect: Bool {
        if case .correct = result {
            return true
        }
        return false
    }
}

// MARK: - Typing Input View

struct TypingInputView: View {
    @Binding var input: String
    var isFocused: FocusState<Bool>.Binding
    let expectedWord: String
    let startTime: Date?
    let onResult: (TestView.TypingResultType) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("英単語を入力してください")
                .font(.rpSubheadline)
                .foregroundColor(.rpTextSecondary)

            HStack(spacing: 12) {
                TextField("英単語を入力", text: $input)
                    .textFieldStyle(.plain)
                    .font(.rpBody)
                    .padding(12)
                    .background(Color.rpCardBackground)
                    .cornerRadius(8)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused(isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        checkAnswer()
                    }

                Button {
                    checkAnswer()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(input.isEmpty ? .rpTextSecondary : .rpPrimary)
                }
                .disabled(input.isEmpty)
            }
        }
        .onAppear {
            // 自動でキーボードを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused.wrappedValue = true
            }
        }
    }

    private func checkAnswer() {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let expected = expectedWord.lowercased()

        if trimmedInput == expected {
            // 回答時間を計算
            let responseTime: TimeInterval
            if let start = startTime {
                responseTime = Date().timeIntervalSince(start)
            } else {
                responseTime = 0
            }
            HapticManager.shared.success()
            onResult(.correct(responseTime: responseTime))
        } else {
            HapticManager.shared.error()
            onResult(.incorrect(typed: input))
        }
    }
}

// MARK: - Typing Result View

struct TypingResultView: View {
    let result: TestView.TypingResultType
    let expectedWord: String
    var allCards: [Card] = []

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isCorrect ? .rpSuccess : .rpError)

            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? "正解！" : "惜しい！")
                    .font(.rpHeadline)
                    .foregroundColor(isCorrect ? .rpSuccess : .rpError)

                if case .incorrect(let typed) = result {
                    HStack(spacing: 4) {
                        Text("あなたの入力: \(typed)")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)

                        // 入力した単語が他のカードに存在する場合、その日本語を表示
                        if let matchedJapanese = findJapaneseMeaning(for: typed) {
                            Text("(\(matchedJapanese))")
                                .font(.rpCaption)
                                .foregroundColor(.rpWarning)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.rpSuccess.opacity(0.1) : Color.rpError.opacity(0.1))
        )
        .padding(.horizontal, 32)
    }

    private var isCorrect: Bool {
        if case .correct = result {
            return true
        }
        return false
    }

    /// 入力した英単語に一致するカードの日本語を検索
    private func findJapaneseMeaning(for input: String) -> String? {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedInput.isEmpty else { return nil }

        // 現在の正解と同じ場合は表示しない
        if normalizedInput == expectedWord.lowercased() {
            return nil
        }

        // 英語が一致するカードを検索
        for card in allCards {
            if card.english.lowercased() == normalizedInput {
                return card.japanese
            }
            // 過去形・過去分詞も検索
            if let pastTense = card.pastTense, pastTense.lowercased() == normalizedInput {
                return "\(card.japanese)の過去形"
            }
            if let pastParticiple = card.pastParticiple, pastParticiple.lowercased() == normalizedInput {
                return "\(card.japanese)の過去分詞"
            }
        }
        return nil
    }
}

// MARK: - Conjugation Input View

/// 活用形の複合入力UI
struct ConjugationInputView: View {
    let card: Card
    let mode: ConjugationMode
    @Binding var presentInput: String
    @Binding var pastInput: String
    @Binding var pastParticipleInput: String
    var presentFocused: FocusState<Bool>.Binding
    var pastFocused: FocusState<Bool>.Binding
    var pastParticipleFocused: FocusState<Bool>.Binding
    let onResult: (TestView.ConjugationResultType) -> Void

    /// 過去形が必要か
    private var requiresPast: Bool {
        (mode == .presentAndPast || mode == .allForms) && card.pastTense != nil
    }

    /// 過去分詞が必要か
    private var requiresPastParticiple: Bool {
        mode == .allForms && card.pastParticiple != nil
    }

    /// 全ての必須フィールドが入力済みか
    private var canSubmit: Bool {
        let presentOk = !presentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let pastOk = !requiresPast || !pastInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let ppOk = !requiresPastParticiple || !pastParticipleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return presentOk && pastOk && ppOk
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("活用形を入力してください")
                .font(.rpSubheadline)
                .foregroundColor(.rpTextSecondary)

            VStack(spacing: 12) {
                // 現在形（原形）
                HStack {
                    Text("原形")
                        .font(.rpCaption)
                        .foregroundColor(.rpTextSecondary)
                        .frame(width: 60, alignment: .trailing)

                    TextField("原形を入力", text: $presentInput)
                        .textFieldStyle(.plain)
                        .font(.rpBody)
                        .padding(10)
                        .background(Color.rpCardBackground)
                        .cornerRadius(8)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused(presentFocused)
                        .submitLabel(requiresPast ? .next : .done)
                        .onSubmit {
                            if requiresPast {
                                // 次のフィールドへ移動
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pastFocused.wrappedValue = true
                                }
                            } else if canSubmit {
                                // 最後のフィールドで全て入力済みなら判定
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    checkAnswer()
                                }
                            }
                        }
                }

                // 過去形
                if requiresPast {
                    HStack {
                        Text("過去形")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                            .frame(width: 60, alignment: .trailing)

                        TextField("過去形を入力", text: $pastInput)
                            .textFieldStyle(.plain)
                            .font(.rpBody)
                            .padding(10)
                            .background(Color.rpCardBackground)
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused(pastFocused)
                            .submitLabel(requiresPastParticiple ? .next : .done)
                            .onSubmit {
                                if requiresPastParticiple {
                                    // 次のフィールドへ移動
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        pastParticipleFocused.wrappedValue = true
                                    }
                                } else if canSubmit {
                                    // 最後のフィールドで全て入力済みなら判定
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        checkAnswer()
                                    }
                                }
                            }
                    }
                }

                // 過去分詞
                if requiresPastParticiple {
                    HStack {
                        Text("過去分詞")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                            .frame(width: 60, alignment: .trailing)

                        TextField("過去分詞を入力", text: $pastParticipleInput)
                            .textFieldStyle(.plain)
                            .font(.rpBody)
                            .padding(10)
                            .background(Color.rpCardBackground)
                            .cornerRadius(8)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused(pastParticipleFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                // 最後のフィールドで全て入力済みなら判定
                                if canSubmit {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        checkAnswer()
                                    }
                                }
                            }
                    }
                }
            }

            // 判定ボタン
            Button {
                checkAnswer()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("判定する")
                }
            }
            .buttonStyle(RPSecondaryButtonStyle(isEnabled: canSubmit))
            .disabled(!canSubmit)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentFocused.wrappedValue = true
            }
        }
    }

    private func checkAnswer() {
        // 入力値をトリムして正規化（不可視文字・特殊スペースも除去）
        let trimmedPresent = normalizeInput(presentInput)
        let expectedPresent = normalizeInput(card.english)
        let presentCorrect = trimmedPresent == expectedPresent

        // デバッグログ
        print("=== Conjugation Check ===")
        print("Present: '\(trimmedPresent)' (len:\(trimmedPresent.count)) vs '\(expectedPresent)' (len:\(expectedPresent.count)) -> \(presentCorrect)")
        if trimmedPresent != expectedPresent {
            print("  Bytes present: \(Array(trimmedPresent.utf8))")
            print("  Bytes expected: \(Array(expectedPresent.utf8))")
        }

        var pastCorrect: Bool? = nil
        if requiresPast, let expected = card.pastTense {
            let trimmedPast = normalizeInput(pastInput)
            let expectedPast = normalizeInput(expected)
            pastCorrect = trimmedPast == expectedPast
            print("Past: '\(trimmedPast)' (len:\(trimmedPast.count)) vs '\(expectedPast)' (len:\(expectedPast.count)) -> \(pastCorrect ?? false)")
            if trimmedPast != expectedPast {
                print("  Bytes past: \(Array(trimmedPast.utf8))")
                print("  Bytes expected: \(Array(expectedPast.utf8))")
            }
        }

        var ppCorrect: Bool? = nil
        if requiresPastParticiple, let expected = card.pastParticiple {
            let trimmedPP = normalizeInput(pastParticipleInput)
            let expectedPP = normalizeInput(expected)
            ppCorrect = trimmedPP == expectedPP
            print("PP: '\(trimmedPP)' (len:\(trimmedPP.count)) vs '\(expectedPP)' (len:\(expectedPP.count)) -> \(ppCorrect ?? false)")
        }
        print("=========================")

        let result = TestView.ConjugationResultType(
            presentCorrect: presentCorrect,
            pastCorrect: pastCorrect,
            pastParticipleCorrect: ppCorrect,
            presentInput: presentInput,
            pastInput: requiresPast ? pastInput : nil,
            pastParticipleInput: requiresPastParticiple ? pastParticipleInput : nil
        )

        if result.isAllCorrect {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }

        onResult(result)
    }

    /// 入力文字列を正規化（不可視文字、特殊スペース、スマートクォート等を除去）
    private func normalizeInput(_ input: String) -> String {
        var result = input
        // 通常のトリム
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        // 小文字化
        result = result.lowercased()
        // ゼロ幅文字を除去
        result = result.replacingOccurrences(of: "\u{200B}", with: "") // Zero Width Space
        result = result.replacingOccurrences(of: "\u{200C}", with: "") // Zero Width Non-Joiner
        result = result.replacingOccurrences(of: "\u{200D}", with: "") // Zero Width Joiner
        result = result.replacingOccurrences(of: "\u{FEFF}", with: "") // BOM
        // 特殊スペースを通常スペースに変換後除去
        result = result.replacingOccurrences(of: "\u{00A0}", with: " ") // Non-Breaking Space
        result = result.replacingOccurrences(of: "\u{2003}", with: " ") // Em Space
        result = result.replacingOccurrences(of: "\u{2002}", with: " ") // En Space
        result = result.trimmingCharacters(in: .whitespaces)
        return result
    }
}

// MARK: - Conjugation Result View

/// 活用形の結果表示UI
struct ConjugationResultView: View {
    let result: TestView.ConjugationResultType
    let card: Card
    let mode: ConjugationMode
    var allCards: [Card] = []

    var body: some View {
        VStack(spacing: 12) {
            // 全体の結果
            HStack(spacing: 12) {
                Image(systemName: result.isAllCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(result.isAllCorrect ? .rpSuccess : .rpError)

                Text(result.isAllCorrect ? "全問正解！" : "惜しい！")
                    .font(.rpHeadline)
                    .foregroundColor(result.isAllCorrect ? .rpSuccess : .rpError)

                Spacer()
            }

            // 各活用形の詳細
            VStack(alignment: .leading, spacing: 8) {
                // 原形
                FormResultRow(
                    label: "原形",
                    userInput: result.presentInput,
                    expected: card.english,
                    isCorrect: result.presentCorrect,
                    allCards: allCards
                )

                // 過去形
                if let pastCorrect = result.pastCorrect,
                   let expected = card.pastTense,
                   let userInput = result.pastInput {
                    FormResultRow(
                        label: "過去形",
                        userInput: userInput,
                        expected: expected,
                        isCorrect: pastCorrect,
                        allCards: allCards
                    )
                }

                // 過去分詞
                if let ppCorrect = result.pastParticipleCorrect,
                   let expected = card.pastParticiple,
                   let userInput = result.pastParticipleInput {
                    FormResultRow(
                        label: "過去分詞",
                        userInput: userInput,
                        expected: expected,
                        isCorrect: ppCorrect,
                        allCards: allCards
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.isAllCorrect ? Color.rpSuccess.opacity(0.1) : Color.rpError.opacity(0.1))
        )
        .padding(.horizontal, 32)
    }
}

/// 各活用形の結果行
struct FormResultRow: View {
    let label: String
    let userInput: String
    let expected: String
    let isCorrect: Bool
    var allCards: [Card] = []

    var body: some View {
        HStack {
            Text(label)
                .font(.rpCaption)
                .foregroundColor(.rpTextSecondary)
                .frame(width: 60, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                // ユーザーの入力値を表示（間違いの場合は日本語訳も表示）
                HStack(spacing: 4) {
                    Text(userInput.isEmpty ? "(未入力)" : userInput)
                        .font(.rpBody)
                        .foregroundColor(isCorrect ? .rpSuccess : .rpError)

                    // 入力した単語が他のカードに存在する場合、その日本語を表示
                    if !isCorrect, let matchedJapanese = findJapaneseMeaning(for: userInput) {
                        Text("(\(matchedJapanese))")
                            .font(.rpCaption)
                            .foregroundColor(.rpWarning)
                    }
                }

                // 不正解の場合は正解も表示
                if !isCorrect {
                    Text("正解: \(expected)")
                        .font(.rpCaption)
                        .foregroundColor(.rpTextSecondary)
                }
            }

            Spacer()

            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isCorrect ? .rpSuccess : .rpError)
        }
    }

    /// 入力した英単語に一致するカードの日本語を検索
    private func findJapaneseMeaning(for input: String) -> String? {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedInput.isEmpty else { return nil }

        // 現在の正解と同じ場合は表示しない
        if normalizedInput == expected.lowercased() {
            return nil
        }

        // 英語が一致するカードを検索
        for card in allCards {
            if card.english.lowercased() == normalizedInput {
                return card.japanese
            }
            // 過去形・過去分詞も検索
            if let pastTense = card.pastTense, pastTense.lowercased() == normalizedInput {
                return "\(card.japanese)の過去形"
            }
            if let pastParticiple = card.pastParticiple, pastParticiple.lowercased() == normalizedInput {
                return "\(card.japanese)の過去分詞"
            }
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, Deck.self, configurations: config)

    // サンプルカードを作成
    let deck = Deck(name: "テスト", categoryId: "custom")
    container.mainContext.insert(deck)

    let card1 = Card(japanese: "重要な", english: "important", phonetic: "/ɪmˈpɔːrtənt/", example: "This is an important test.", exampleJapanese: "これは重要なテストです。")
    card1.deck = deck
    container.mainContext.insert(card1)

    return TestView(cards: [card1], sessionType: .mixed)
        .modelContainer(container)
}
