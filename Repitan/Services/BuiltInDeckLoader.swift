import Foundation
import SwiftData

/// 組み込み単語帳の読み込みを担当
class BuiltInDeckLoader {

    /// 組み込み単語帳を読み込む（全単語帳）
    @MainActor
    static func loadBuiltInDecks(modelContext: ModelContext) async {
        // 学年レベル別単語帳
        let gradeFiles = [
            "junior_high_1",
            "junior_high_2",
            "junior_high_3",
        ]

        for fileName in gradeFiles {
            await loadDeckFromFile(fileName: fileName, modelContext: modelContext, isActive: false)
        }

        // 特別単語帳（不規則動詞）
        await loadDeckFromFile(fileName: "irregular_verbs", modelContext: modelContext, isActive: false)

        try? modelContext.save()
    }

    /// 不規則動詞単語帳を読み込む
    /// - Parameters:
    ///   - modelContext: SwiftData モデルコンテキスト
    ///   - isActive: アクティブ状態
    /// - Returns: 読み込んだ単語帳（失敗時はnil）
    @MainActor
    @discardableResult
    static func loadIrregularVerbsDeck(modelContext: ModelContext, isActive: Bool = false) async -> Deck? {
        return await loadDeckFromFile(fileName: "irregular_verbs", modelContext: modelContext, isActive: isActive)
    }

    /// 特定の学年の単語帳を読み込む
    /// - Parameters:
    ///   - grade: 学年（1, 2, 3）
    ///   - modelContext: SwiftData モデルコンテキスト
    /// - Returns: 読み込んだ単語帳（失敗時はnil）
    @MainActor
    @discardableResult
    static func loadDeckForGrade(grade: Int, modelContext: ModelContext) async -> Deck? {
        let fileName = "junior_high_\(grade)"
        return await loadDeckFromFile(fileName: fileName, modelContext: modelContext, isActive: true)
    }

    /// 全学年の単語帳を読み込む（選択した学年をアクティブに）
    /// - Parameters:
    ///   - activeGrade: アクティブにする学年（nilの場合は全てアクティブ）
    ///   - modelContext: SwiftData モデルコンテキスト
    @MainActor
    static func loadAllGradeDecks(activeGrade: Int?, modelContext: ModelContext) async {
        let grades = [1, 2, 3]

        for grade in grades {
            let isActive = (activeGrade == nil) || (grade == activeGrade)
            let fileName = "junior_high_\(grade)"
            await loadDeckFromFile(fileName: fileName, modelContext: modelContext, isActive: isActive)
        }

        try? modelContext.save()
    }

    /// 特定の教科書・学年の単語帳を読み込む（後方互換性）
    /// - Parameters:
    ///   - textbook: 教科書ID（無視される - 学年レベルの単語帳を使用）
    ///   - grade: 学年（1, 2, 3）
    ///   - modelContext: SwiftData モデルコンテキスト
    /// - Returns: 読み込んだ単語帳（失敗時はnil）
    @MainActor
    @discardableResult
    static func loadDeckForTextbook(textbook: String, grade: Int, modelContext: ModelContext) async -> Deck? {
        // 教科書別ではなく学年レベル別の単語帳を読み込む
        return await loadDeckForGrade(grade: grade, modelContext: modelContext)
    }

    /// 既存の単語帳をバージョンチェックして更新（アクティブ状態は維持）
    /// - Parameters:
    ///   - fileName: JSONファイル名（拡張子なし）
    ///   - modelContext: SwiftData モデルコンテキスト
    @MainActor
    static func checkAndUpdateDeck(fileName: String, modelContext: ModelContext) async {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deckData = try? JSONDecoder().decode(DeckData.self, from: data) else {
            return
        }

        // 既存の単語帳を検索
        let categoryId = deckData.categoryId
        let descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.isBuiltIn && $0.categoryId == categoryId }
        )
        guard let existing = try? modelContext.fetch(descriptor), let deck = existing.first else {
            return
        }

        // バージョン比較してカード情報を更新
        let needsUpdate = shouldUpdateDeck(currentVersion: deck.builtInVersion, newVersion: deckData.version)
        if needsUpdate {
            updateExistingCards(deck: deck, deckData: deckData, modelContext: modelContext)
            deck.builtInVersion = deckData.version
            try? modelContext.save()
            print("Updated deck \(deck.name) to version \(deckData.version)")
        }
    }

    /// JSONファイルから単語帳を読み込む
    @MainActor
    @discardableResult
    private static func loadDeckFromFile(fileName: String, modelContext: ModelContext, isActive: Bool) async -> Deck? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deckData = try? JSONDecoder().decode(DeckData.self, from: data) else {
            print("Failed to load deck file: \(fileName).json")
            return nil
        }

        // 既存チェック
        let categoryId = deckData.categoryId
        let descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.isBuiltIn && $0.categoryId == categoryId }
        )
        if let existing = try? modelContext.fetch(descriptor), let deck = existing.first {
            // 既存の単語帳がある場合はアクティブ状態を更新
            deck.isActive = isActive

            // バージョン比較してカード情報を更新
            let needsUpdate = shouldUpdateDeck(currentVersion: deck.builtInVersion, newVersion: deckData.version)
            if needsUpdate {
                updateExistingCards(deck: deck, deckData: deckData, modelContext: modelContext)
                deck.builtInVersion = deckData.version
                try? modelContext.save()
                print("Updated deck \(deck.name) to version \(deckData.version)")
            }

            return deck
        }

        // 単語帳作成
        let deck = Deck(name: deckData.name, categoryId: deckData.categoryId)
        deck.isBuiltIn = true
        deck.isActive = isActive
        deck.builtInVersion = deckData.version
        modelContext.insert(deck)

        // カード作成
        for cardData in deckData.cards {
            let card = Card(
                japanese: cardData.japanese,
                english: cardData.english,
                phonetic: cardData.phonetic,
                example: cardData.example,
                exampleJapanese: cardData.exampleJapanese,
                partOfSpeech: cardData.partOfSpeech,
                pastTense: cardData.pastTense,
                pastParticiple: cardData.pastParticiple,
                pastTensePhonetic: cardData.pastTensePhonetic,
                pastParticiplePhonetic: cardData.pastParticiplePhonetic,
                deck: deck
            )
            modelContext.insert(card)
        }

        try? modelContext.save()
        print("Loaded deck: \(deckData.name) with \(deckData.cards.count) cards (version \(deckData.version))")
        return deck
    }

    // MARK: - Version Management

    /// バージョン比較して更新が必要か判定
    /// - Parameters:
    ///   - currentVersion: 現在のバージョン（nil = 未設定）
    ///   - newVersion: 新しいバージョン
    /// - Returns: 更新が必要な場合true
    private static func shouldUpdateDeck(currentVersion: String?, newVersion: String) -> Bool {
        guard let current = currentVersion else {
            // バージョン未設定の場合は常に更新
            return true
        }
        // セマンティックバージョニングで比較
        return compareVersions(current, newVersion) < 0
    }

    /// セマンティックバージョン比較
    /// - Returns: current < new なら負、current == new なら0、current > new なら正
    private static func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 != p2 {
                return p1 - p2
            }
        }
        return 0
    }

    /// 既存カードを更新（学習進捗は保持）
    /// - Parameters:
    ///   - deck: 既存の単語帳
    ///   - deckData: 新しいJSONデータ
    ///   - modelContext: モデルコンテキスト
    private static func updateExistingCards(deck: Deck, deckData: DeckData, modelContext: ModelContext) {
        let existingCards = deck.cards
        var updatedCount = 0
        var addedCount = 0

        // JSONデータのカードをenglishをキーにしたマップに変換
        var cardDataMap: [String: CardData] = [:]
        for cardData in deckData.cards {
            cardDataMap[cardData.english.lowercased()] = cardData
        }

        // 既存カードを更新（英単語で照合）
        for card in existingCards {
            if let cardData = cardDataMap[card.english.lowercased()] {
                // 日本語訳を更新
                if card.japanese != cardData.japanese {
                    card.japanese = cardData.japanese
                    updatedCount += 1
                }
                // 発音記号を更新
                if let phonetic = cardData.phonetic, card.phonetic != phonetic {
                    card.phonetic = phonetic
                }
                // 品詞を更新
                if let partOfSpeech = cardData.partOfSpeech, card.partOfSpeech != partOfSpeech {
                    card.partOfSpeech = partOfSpeech
                }
                // 例文を更新
                if let example = cardData.example, card.example != example {
                    card.example = example
                }
                if let exampleJapanese = cardData.exampleJapanese, card.exampleJapanese != exampleJapanese {
                    card.exampleJapanese = exampleJapanese
                }
                // 過去形・過去分詞を更新
                if let pastTense = cardData.pastTense, card.pastTense != pastTense {
                    card.pastTense = pastTense
                }
                if let pastParticiple = cardData.pastParticiple, card.pastParticiple != pastParticiple {
                    card.pastParticiple = pastParticiple
                }
                if let pastTensePhonetic = cardData.pastTensePhonetic, card.pastTensePhonetic != pastTensePhonetic {
                    card.pastTensePhonetic = pastTensePhonetic
                }
                if let pastParticiplePhonetic = cardData.pastParticiplePhonetic, card.pastParticiplePhonetic != pastParticiplePhonetic {
                    card.pastParticiplePhonetic = pastParticiplePhonetic
                }

                // 処理済みマークとしてマップから削除
                cardDataMap.removeValue(forKey: card.english.lowercased())
            }
        }

        // 新規カードを追加（マップに残っているもの）
        for (_, cardData) in cardDataMap {
            let card = Card(
                japanese: cardData.japanese,
                english: cardData.english,
                phonetic: cardData.phonetic,
                example: cardData.example,
                exampleJapanese: cardData.exampleJapanese,
                partOfSpeech: cardData.partOfSpeech,
                pastTense: cardData.pastTense,
                pastParticiple: cardData.pastParticiple,
                pastTensePhonetic: cardData.pastTensePhonetic,
                pastParticiplePhonetic: cardData.pastParticiplePhonetic,
                deck: deck
            )
            modelContext.insert(card)
            addedCount += 1
        }

        print("Deck update: \(updatedCount) cards updated, \(addedCount) cards added")
    }
}

// MARK: - Data Structures for JSON Decoding

/// 単語帳データ（JSON用）
struct DeckData: Codable {
    let deckId: String
    let name: String
    let categoryId: String
    let version: String
    let cards: [CardData]
}

/// カードデータ（JSON用）
struct CardData: Codable {
    let japanese: String
    let english: String
    let phonetic: String?
    let example: String?
    let exampleJapanese: String?
    let unit: Int?
    let partOfSpeech: String?
    let pastTense: String?
    let pastParticiple: String?
    let pastTensePhonetic: String?
    let pastParticiplePhonetic: String?
}
