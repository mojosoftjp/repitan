import Foundation
import SwiftData
import UniformTypeIdentifiers

/// CSVファイルから単語カードをインポートするサービス
/// サポートするCSV形式:
/// - 必須列: japanese, english
/// - オプション列: phonetic, example, exampleJapanese, pastTense, pastParticiple, pastTensePhonetic, pastParticiplePhonetic
@MainActor
class CSVImporter {

    // MARK: - Types

    /// インポート結果
    struct ImportResult {
        let successCount: Int
        let skipCount: Int
        let errorCount: Int
        let errors: [ImportError]

        var totalProcessed: Int {
            successCount + skipCount + errorCount
        }

        static let empty = ImportResult(successCount: 0, skipCount: 0, errorCount: 0, errors: [])
    }

    /// インポートエラー
    struct ImportError: Identifiable {
        let id = UUID()
        let line: Int
        let message: String
    }

    /// CSVの列マッピング
    struct ColumnMapping {
        var japanese: Int?
        var english: Int?
        var phonetic: Int?
        var example: Int?
        var exampleJapanese: Int?
        var pastTense: Int?
        var pastParticiple: Int?
        var pastTensePhonetic: Int?
        var pastParticiplePhonetic: Int?

        var isValid: Bool {
            japanese != nil && english != nil
        }
    }

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// CSVファイルをインポート
    /// - Parameters:
    ///   - url: CSVファイルのURL
    ///   - deck: インポート先の単語帳
    ///   - hasHeader: ヘッダー行があるか
    /// - Returns: インポート結果
    func importCSV(from url: URL, to deck: Deck, hasHeader: Bool = true) async throws -> ImportResult {
        // セキュリティスコープアクセスを開始
        guard url.startAccessingSecurityScopedResource() else {
            throw AppError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // ファイル内容を読み込み
        let content = try String(contentsOf: url, encoding: .utf8)
        return try await importCSVContent(content, to: deck, hasHeader: hasHeader)
    }

    /// CSV文字列をインポート
    /// - Parameters:
    ///   - content: CSV文字列
    ///   - deck: インポート先の単語帳
    ///   - hasHeader: ヘッダー行があるか
    /// - Returns: インポート結果
    func importCSVContent(_ content: String, to deck: Deck, hasHeader: Bool = true) async throws -> ImportResult {
        var lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw AppError.invalidCSVFormat("CSVファイルが空です")
        }

        // ヘッダー解析
        let mapping: ColumnMapping
        if hasHeader {
            mapping = parseHeader(lines.removeFirst())
        } else {
            // ヘッダーなしの場合、デフォルトマッピング (japanese, english, ...)
            mapping = ColumnMapping(
                japanese: 0,
                english: 1,
                phonetic: 2,
                example: 3,
                exampleJapanese: 4,
                pastTense: 5,
                pastParticiple: 6,
                pastTensePhonetic: 7,
                pastParticiplePhonetic: 8
            )
        }

        guard mapping.isValid else {
            throw AppError.invalidCSVFormat("必須列（japanese, english）が見つかりません")
        }

        // カードをインポート
        var successCount = 0
        var skipCount = 0
        var errors: [ImportError] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = hasHeader ? index + 2 : index + 1

            do {
                let card = try parseRow(line, mapping: mapping, lineNumber: lineNumber)

                // 重複チェック
                if isDuplicate(japanese: card.japanese, english: card.english, in: deck) {
                    skipCount += 1
                    continue
                }

                card.deck = deck
                modelContext.insert(card)
                successCount += 1
            } catch let error as AppError {
                errors.append(ImportError(line: lineNumber, message: error.localizedDescription))
            } catch {
                errors.append(ImportError(line: lineNumber, message: error.localizedDescription))
            }
        }

        // 保存
        do {
            try modelContext.save()
        } catch {
            throw AppError.saveFailed("インポートデータの保存に失敗しました: \(error.localizedDescription)")
        }

        return ImportResult(
            successCount: successCount,
            skipCount: skipCount,
            errorCount: errors.count,
            errors: errors
        )
    }

    // MARK: - Private Methods

    /// ヘッダー行を解析して列マッピングを作成
    private func parseHeader(_ header: String) -> ColumnMapping {
        let columns = parseCSVRow(header).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var mapping = ColumnMapping()

        for (index, column) in columns.enumerated() {
            switch column {
            case "japanese", "日本語", "意味", "和訳":
                mapping.japanese = index
            case "english", "英語", "単語", "word":
                mapping.english = index
            case "phonetic", "発音記号", "発音":
                mapping.phonetic = index
            case "example", "例文", "例文（英語）":
                mapping.example = index
            case "examplejapanese", "example_japanese", "例文（日本語）", "例文日本語":
                mapping.exampleJapanese = index
            case "pasttense", "past_tense", "過去形":
                mapping.pastTense = index
            case "pastparticiple", "past_participle", "過去分詞":
                mapping.pastParticiple = index
            case "pasttensephonetic", "past_tense_phonetic", "過去形発音", "過去形発音記号":
                mapping.pastTensePhonetic = index
            case "pastparticiplephonetic", "past_participle_phonetic", "過去分詞発音", "過去分詞発音記号":
                mapping.pastParticiplePhonetic = index
            default:
                break
            }
        }

        return mapping
    }

    /// CSV行を解析してカードを作成
    private func parseRow(_ row: String, mapping: ColumnMapping, lineNumber: Int) throws -> Card {
        let columns = parseCSVRow(row)

        guard let japaneseIndex = mapping.japanese,
              let englishIndex = mapping.english,
              japaneseIndex < columns.count,
              englishIndex < columns.count else {
            throw AppError.invalidCSVFormat("行 \(lineNumber): 必須列が不足しています")
        }

        let japanese = columns[japaneseIndex].trimmingCharacters(in: .whitespaces)
        let english = columns[englishIndex].trimmingCharacters(in: .whitespaces)

        guard !japanese.isEmpty, !english.isEmpty else {
            throw AppError.invalidCSVFormat("行 \(lineNumber): 日本語または英語が空です")
        }

        let phonetic = mapping.phonetic.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let example = mapping.example.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let exampleJapanese = mapping.exampleJapanese.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let pastTense = mapping.pastTense.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let pastParticiple = mapping.pastParticiple.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let pastTensePhonetic = mapping.pastTensePhonetic.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        let pastParticiplePhonetic = mapping.pastParticiplePhonetic.flatMap { index in
            index < columns.count ? columns[index].trimmingCharacters(in: .whitespaces) : nil
        }

        return Card(
            japanese: japanese,
            english: english,
            phonetic: phonetic?.isEmpty == true ? nil : phonetic,
            example: example?.isEmpty == true ? nil : example,
            exampleJapanese: exampleJapanese?.isEmpty == true ? nil : exampleJapanese,
            pastTense: pastTense?.isEmpty == true ? nil : pastTense,
            pastParticiple: pastParticiple?.isEmpty == true ? nil : pastParticiple,
            pastTensePhonetic: pastTensePhonetic?.isEmpty == true ? nil : pastTensePhonetic,
            pastParticiplePhonetic: pastParticiplePhonetic?.isEmpty == true ? nil : pastParticiplePhonetic
        )
    }

    /// CSV行をパース（引用符対応）
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)

        return result
    }

    /// 重複チェック
    private func isDuplicate(japanese: String, english: String, in deck: Deck) -> Bool {
        let existingCards = deck.cards
        return existingCards.contains { card in
            card.japanese == japanese && card.english == english
        }
    }
}

// MARK: - UTType Extension

extension UTType {
    /// CSVファイルタイプ
    static var csv: UTType {
        UTType(filenameExtension: "csv") ?? .commaSeparatedText
    }
}
