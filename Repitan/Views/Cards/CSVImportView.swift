import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// CSVインポート画面
struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var isImporting = false
    @State private var hasHeader = true
    @State private var importResult: CSVImporter.ImportResult?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.rpPrimary)

                    Text("CSVファイルから単語をインポート")
                        .font(.rpTitle3)
                        .foregroundColor(.rpTextPrimary)

                    Text("単語帳: \(deck.name)")
                        .font(.rpSubheadline)
                        .foregroundColor(.rpTextSecondary)
                }
                .padding(.top, 32)

                Spacer()

                // CSV形式の説明
                VStack(alignment: .leading, spacing: 16) {
                    Text("CSVファイルの形式")
                        .font(.rpHeadline)
                        .foregroundColor(.rpTextPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        FormatRow(label: "必須", columns: "japanese, english")
                        FormatRow(label: "任意", columns: "phonetic, example, exampleJapanese")
                        FormatRow(label: "動詞", columns: "pastTense, pastParticiple")
                    }

                    Text("例:")
                        .font(.rpSubheadline)
                        .foregroundColor(.rpTextSecondary)
                        .padding(.top, 8)

                    Text("japanese,english,pastTense,pastParticiple\n走る,run,ran,run\n行く,go,went,gone")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.rpTextSecondary)
                        .padding(12)
                        .background(Color.rpCardBackground)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.rpBackground)
                .cornerRadius(12)
                .padding(.horizontal)

                // オプション
                VStack(spacing: 12) {
                    Toggle(isOn: $hasHeader) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ヘッダー行あり")
                                .font(.rpBody)
                                .foregroundColor(.rpTextPrimary)
                            Text("1行目を列名として使用")
                                .font(.rpCaption)
                                .foregroundColor(.rpTextSecondary)
                        }
                    }
                    .padding()
                    .background(Color.rpCardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()

                // インポートボタン
                Button {
                    isImporting = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("CSVファイルを選択")
                    }
                }
                .buttonStyle(RPPrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.rpBackground.ignoresSafeArea())
            .navigationTitle("CSVインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("インポート完了", isPresented: $showResult) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let result = importResult {
                    Text(formatResultMessage(result))
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importCSV(from: url)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func importCSV(from url: URL) {
        Task {
            do {
                let importer = CSVImporter(modelContext: modelContext)
                let result = try await importer.importCSV(from: url, to: deck, hasHeader: hasHeader)
                importResult = result
                showResult = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func formatResultMessage(_ result: CSVImporter.ImportResult) -> String {
        var message = "\(result.successCount)件の単語をインポートしました"

        if result.skipCount > 0 {
            message += "\n\(result.skipCount)件は重複のためスキップ"
        }

        if result.errorCount > 0 {
            message += "\n\(result.errorCount)件でエラー発生"
        }

        return message
    }
}

// MARK: - Format Row

struct FormatRow: View {
    let label: String
    let columns: String

    private var backgroundColor: Color {
        switch label {
        case "必須":
            return .rpError
        case "動詞":
            return .rpPrimary
        default:
            return .rpTextSecondary
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.rpCaption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .cornerRadius(4)
                .frame(width: 48)

            Text(columns)
                .font(.rpSubheadline)
                .foregroundColor(.rpTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Deck.self, Card.self, configurations: config)

    let deck = Deck(name: "テスト単語帳", categoryId: "custom")
    container.mainContext.insert(deck)

    return CSVImportView(deck: deck)
        .modelContainer(container)
}
