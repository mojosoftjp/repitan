import SwiftUI
import SwiftData

/// 設定画面
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            List {
                // 学習設定
                Section(header: Text("学習設定")) {
                    NavigationLink {
                        LearningSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "book.fill",
                            iconColor: .rpPrimary,
                            title: "学習設定",
                            subtitle: "1日の目標: \(settings.dailyNewCardGoal)語"
                        )
                    }
                }

                // 通知
                Section(header: Text("通知")) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .rpWarning,
                            title: "通知設定",
                            subtitle: settings.notificationEnabled ? "オン" : "オフ"
                        )
                    }
                }

                // サウンド・触覚
                Section(header: Text("サウンド・触覚")) {
                    Toggle(isOn: Bindable(settings).soundEnabled) {
                        SettingsRow(
                            icon: "speaker.wave.2.fill",
                            iconColor: .rpSecondary,
                            title: "サウンド効果"
                        )
                    }

                    Toggle(isOn: Bindable(settings).hapticEnabled) {
                        SettingsRow(
                            icon: "hand.tap.fill",
                            iconColor: .rpSecondary,
                            title: "触覚フィードバック"
                        )
                    }
                }

                // プレミアム
                Section(header: Text("プレミアム")) {
                    NavigationLink {
                        PremiumView()
                    } label: {
                        SettingsRow(
                            icon: settings.isPremium ? "star.fill" : "star",
                            iconColor: .rpStreak,
                            title: settings.isPremium ? "プレミアム会員" : "広告を削除",
                            subtitle: settings.isPremium ? "ありがとうございます！" : "¥480"
                        )
                    }
                }

                // 統計
                Section(header: Text("データ")) {
                    NavigationLink {
                        StatsView()
                    } label: {
                        SettingsRow(
                            icon: "chart.bar.fill",
                            iconColor: .rpSuccess,
                            title: "学習統計"
                        )
                    }

                    NavigationLink {
                        AchievementsView()
                    } label: {
                        SettingsRow(
                            icon: "trophy.fill",
                            iconColor: .rpWarning,
                            title: "実績"
                        )
                    }
                }

                // アプリ情報
                Section(header: Text("アプリ情報")) {
                    NavigationLink {
                        HelpView()
                    } label: {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .rpPrimary,
                            title: "ヘルプ"
                        )
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .rpTextSecondary,
                            title: "リピたんについて"
                        )
                    }

                    Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXX?action=write-review")!) {
                        SettingsRow(
                            icon: "heart.fill",
                            iconColor: .rpError,
                            title: "アプリを評価する"
                        )
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.rpBody)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rpBody)
                    .foregroundColor(.rpTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.rpCaption1)
                        .foregroundColor(.rpTextSecondary)
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct LearningSettingsView: View {
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        Form {
            Section(header: Text("1日の目標")) {
                Stepper("新規カード: \(settings.dailyNewCardGoal)語", value: Bindable(settings).dailyNewCardGoal, in: 1...50)
                Stepper("復習上限: \(settings.dailyReviewLimit)語", value: Bindable(settings).dailyReviewLimit, in: 10...200)
            }

            Section(header: Text("学習ステップ（分）")) {
                Text("3分 → 20分 → 卒業")
                    .font(.rpBody)
                    .foregroundColor(.rpTextSecondary)
            }

            Section(header: Text("回答方法")) {
                Picker("優先する回答方法", selection: Bindable(settings).preferredAnswerMethod) {
                    ForEach(AnswerMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                Toggle(isOn: Bindable(settings).useSpeechRecognition) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("音声認識モード")
                            .font(.rpBody)
                        Text("マイクで発音を確認できます")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                    }
                }
            }

            Section(header: Text("発音")) {
                Toggle(isOn: Bindable(settings).autoPlayPronunciation) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("自動発音再生")
                            .font(.rpBody)
                        Text("答えを表示した時に自動再生")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                    }
                }
            }
        }
        .navigationTitle("学習設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @Query private var settingsArray: [UserSettings]

    private var settings: UserSettings {
        settingsArray.first ?? UserSettings()
    }

    var body: some View {
        Form {
            Section {
                Toggle("リマインダー通知", isOn: Binding(
                    get: { settings.notificationEnabled },
                    set: { newValue in
                        settings.notificationEnabled = newValue
                        handleNotificationToggle(enabled: newValue)
                    }
                ))
            }

            if settings.notificationEnabled {
                Section(header: Text("通知時刻")) {
                    DatePicker(
                        "通知時刻",
                        selection: Binding(
                            get: { settings.notificationTime ?? Date() },
                            set: { settings.notificationTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }

                Section(header: Text("通知の種類")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.rpWarning)
                            Text("復習リマインダー")
                                .font(.rpBody)
                        }
                        Text("復習時間になったらまとめて通知します")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.rpStreak)
                            Text("毎日のリマインダー")
                                .font(.rpBody)
                        }
                        Text("毎朝9時に学習を促す通知を送ります")
                            .font(.rpCaption)
                            .foregroundColor(.rpTextSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleNotificationToggle(enabled: Bool) {
        if enabled {
            // 通知を有効化：許可をリクエストして毎日のリマインダーをスケジュール
            Task {
                let granted = await NotificationManager.shared.requestAuthorization()
                if granted {
                    NotificationManager.shared.scheduleDailySummaryNotification()
                }
            }
        } else {
            // 通知を無効化：すべての通知をキャンセル
            NotificationManager.shared.cancelAllNotifications()
        }
    }
}

struct PremiumView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundColor(.rpStreak)

            Text("広告を削除")
                .font(.rpTitle1)

            Text("¥480の1回払いで\n広告なしで学習に集中できます")
                .font(.rpBody)
                .foregroundColor(.rpTextSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                // TODO: StoreKit実装
            } label: {
                Text("購入する - ¥480")
            }
            .buttonStyle(RPPrimaryButtonStyle())
            .padding(.horizontal, 32)

            Button {
                // TODO: リストア
            } label: {
                Text("購入を復元")
                    .font(.rpSubheadline)
                    .foregroundColor(.rpPrimary)
            }

            Spacer()
        }
        .navigationTitle("プレミアム")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var allTimeStats: AllTimeStatsSummary = .empty

    var body: some View {
        List {
            Section(header: Text("全期間")) {
                StatDetailRow(label: "学習したカード", value: "\(allTimeStats.totalCardsStudied)語")
                StatDetailRow(label: "正答率", value: "\(Int(allTimeStats.accuracy * 100))%")
                StatDetailRow(label: "学習時間", value: "\(allTimeStats.totalStudyTimeHours)時間")
                StatDetailRow(label: "学習日数", value: "\(allTimeStats.daysStudied)日")
                StatDetailRow(label: "最長ストリーク", value: "\(allTimeStats.longestStreak)日")
            }
        }
        .navigationTitle("学習統計")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let manager = DailyStatsManager(modelContext: modelContext)
            allTimeStats = manager.getAllTimeStats()
        }
    }
}

struct StatDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.rpTextSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct AchievementsView: View {
    @Query private var achievements: [Achievement]

    var body: some View {
        List {
            ForEach(AchievementType.Category.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(AchievementType.allCases.filter { $0.category == category }, id: \.self) { type in
                        let isUnlocked = achievements.contains { $0.achievementType == type }
                        AchievementRow(type: type, isUnlocked: isUnlocked)
                    }
                }
            }
        }
        .navigationTitle("実績")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementRow: View {
    let type: AchievementType
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(type.icon)
                .font(.system(size: 28))
                .opacity(isUnlocked ? 1 : 0.3)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.rpBodyBold)
                    .foregroundColor(isUnlocked ? .rpTextPrimary : .rpTextSecondary)

                Text(type.description)
                    .font(.rpCaption1)
                    .foregroundColor(.rpTextSecondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.rpSuccess)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.rpTextSecondary)
                }

                HStack {
                    Text("開発者")
                    Spacer()
                    Text("MojoSoft")
                        .foregroundColor(.rpTextSecondary)
                }
            }

            Section {
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    Text("プライバシーポリシー")
                }

                Link(destination: URL(string: "https://example.com/terms")!) {
                    Text("利用規約")
                }
            }
        }
        .navigationTitle("リピたんについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: [
            UserSettings.self,
            Achievement.self,
            DailyStats.self,
        ], inMemory: true)
}
