import SwiftUI
import SwiftData

/// リピたん - 英単語暗記アプリ
/// 中高生向けの間隔反復学習（SM-2アルゴリズム）を使用した英単語学習アプリ
@main
struct RepitanApp: App {
    /// SwiftData モデルコンテナ
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Deck.self,
            Card.self,
            ReviewHistory.self,
            StudySession.self,
            DailyStats.self,
            UserSettings.self,
            Achievement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // スキーマ変更でエラーが発生した場合、データベースを削除して再作成
            print("ModelContainer creation failed, attempting to reset database: \(error)")

            // データベースファイルを削除
            Self.deleteDatabase()

            // 再度ModelContainerを作成
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                print("Database reset successful")
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    /// データベースファイルを削除（開発用）
    private static func deleteDatabase() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let storeURL = appSupport.appendingPathComponent("default.store")
        let walURL = appSupport.appendingPathComponent("default.store-wal")
        let shmURL = appSupport.appendingPathComponent("default.store-shm")

        for url in [storeURL, walURL, shmURL] {
            try? fileManager.removeItem(at: url)
        }
        print("Database files deleted")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupInitialData()
                    requestNotificationPermission()
                }
        }
        .modelContainer(modelContainer)
    }

    /// 通知許可をリクエスト
    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                // UserSettingsの通知設定を更新
                await MainActor.run {
                    let context = modelContainer.mainContext
                    let settingsDescriptor = FetchDescriptor<UserSettings>()
                    if let settings = try? context.fetch(settingsDescriptor).first {
                        // 初回許可時は通知を有効にする
                        if !settings.notificationEnabled {
                            settings.notificationEnabled = true
                            try? context.save()
                        }
                    }
                }
                // 毎日のリマインダーをスケジュール
                NotificationManager.shared.scheduleDailySummaryNotification()
            }
            print("Notification permission: \(granted ? "granted" : "denied")")
        }
    }

    /// 初回起動時のデータセットアップ
    private func setupInitialData() {
        let context = modelContainer.mainContext

        // UserSettingsの確認・作成
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        if let existingSettings = try? context.fetch(settingsDescriptor), existingSettings.isEmpty {
            let settings = UserSettings()
            context.insert(settings)
            print("Created default UserSettings")
        }

        // 既存ユーザーの学習ステップを新しい値に移行
        migrateOldLearningSteps()

        // 変更を保存
        do {
            try context.save()
        } catch {
            print("Failed to save initial data: \(error)")
        }

        // 既存ユーザー向け：新しい組み込み単語帳を自動追加
        loadMissingBuiltInDecks()

        // 既存の組み込み単語帳をバージョンチェック・更新
        checkBuiltInDeckUpdates()
    }

    /// 学習ステップを正しい値に強制設定
    /// 設定画面で変更するUIがないため、常に正しい値を設定
    private func migrateOldLearningSteps() {
        let context = modelContainer.mainContext
        let settingsDescriptor = FetchDescriptor<UserSettings>()

        guard let settings = try? context.fetch(settingsDescriptor).first else { return }

        // 常に正しい値に設定（設定画面で変更できないため）
        if settings.learningSteps != [3, 20] {
            settings.learningSteps = [3, 20]
            print("Set learningSteps to [3, 20]")
        }

        if settings.relearningSteps != [20] {
            settings.relearningSteps = [20]
            print("Set relearningSteps to [20]")
        }
    }

    /// 新しい組み込み単語帳があれば自動的に追加
    private func loadMissingBuiltInDecks() {
        let context = modelContainer.mainContext

        // オンボーディング完了済みかチェック
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        guard let settings = try? context.fetch(settingsDescriptor).first,
              settings.hasCompletedOnboarding else {
            // オンボーディング未完了の場合は何もしない（オンボーディング完了時に読み込まれる）
            return
        }

        // 既存の組み込み単語帳のカテゴリIDを取得
        let deckDescriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )
        let existingCategoryIds = (try? context.fetch(deckDescriptor).map { $0.categoryId }) ?? []

        // 全組み込み単語帳のカテゴリID（学年別 + 不規則動詞）
        let allBuiltInCategories = ["junior_high_1", "junior_high_2", "junior_high_3", "irregular_verbs"]

        // 不足している単語帳を読み込む
        let missingCategories = allBuiltInCategories.filter { !existingCategoryIds.contains($0) }

        if !missingCategories.isEmpty {
            print("Loading missing built-in decks: \(missingCategories)")
            // バックグラウンドで実行してUIをブロックしない
            Task.detached { [modelContainer] in
                let backgroundContext = ModelContext(modelContainer)
                for categoryId in missingCategories {
                    if categoryId == "irregular_verbs" {
                        // 不規則動詞単語帳
                        await BuiltInDeckLoader.loadIrregularVerbsDeck(modelContext: backgroundContext, isActive: false)
                        print("Loaded missing deck: irregular_verbs")
                    } else if let grade = DeckCategoryManager.gradeFromCategory(categoryId) {
                        // 学年別単語帳は非アクティブで追加（ユーザーが選択できるように）
                        await BuiltInDeckLoader.loadDeckForGrade(grade: grade, modelContext: backgroundContext)
                        print("Loaded missing deck for grade \(grade)")
                    }
                }
            }
        }
    }

    /// 既存の組み込み単語帳のバージョンをチェックして更新
    private func checkBuiltInDeckUpdates() {
        let context = modelContainer.mainContext

        // オンボーディング完了済みかチェック
        let settingsDescriptor = FetchDescriptor<UserSettings>()
        guard let settings = try? context.fetch(settingsDescriptor).first,
              settings.hasCompletedOnboarding else {
            return
        }

        // 全組み込み単語帳のファイル名
        let builtInFiles = ["junior_high_1", "junior_high_2", "junior_high_3", "irregular_verbs"]

        // バックグラウンドで実行してUIをブロックしない
        Task.detached { [modelContainer] in
            let backgroundContext = ModelContext(modelContainer)
            for fileName in builtInFiles {
                // loadDeckFromFileはバージョン比較して必要な場合のみ更新する
                await BuiltInDeckLoader.checkAndUpdateDeck(fileName: fileName, modelContext: backgroundContext)
            }
        }
    }
}
