import SwiftUI
import SwiftData

/// オンボーディング画面のメインコンテナ
/// 初回起動時にユーザーを案内するフロー
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var currentPage: OnboardingPage = .welcome
    @State private var selectedGrade: Int? = nil

    /// オンボーディングのページ
    enum OnboardingPage: Int, CaseIterable {
        case welcome = 0
        case gradeSelection = 1
        case completion = 2
    }

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [Color.rpPrimary.opacity(0.1), Color.rpBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // プログレスインジケーター
                if currentPage != .completion {
                    progressIndicator
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                }

                // コンテンツ
                TabView(selection: $currentPage) {
                    WelcomePageView(onNext: goToNext)
                        .tag(OnboardingPage.welcome)

                    GradeSelectionPageView(
                        selectedGrade: $selectedGrade,
                        onNext: completeOnboarding,
                        onBack: goToPrevious
                    )
                    .tag(OnboardingPage.gradeSelection)

                    OnboardingCompletionView()
                        .tag(OnboardingPage.completion)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2) { index in
                Capsule()
                    .fill(index <= currentPage.rawValue ? Color.rpPrimary : Color.rpTextSecondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Navigation

    private func goToNext() {
        withAnimation {
            if let nextPage = OnboardingPage(rawValue: currentPage.rawValue + 1) {
                currentPage = nextPage
            }
        }
    }

    private func goToPrevious() {
        withAnimation {
            if let previousPage = OnboardingPage(rawValue: currentPage.rawValue - 1) {
                currentPage = previousPage
            }
        }
    }

    private func completeOnboarding() {
        // 設定を保存
        if let userSettings = settings.first {
            userSettings.selectedGrade = selectedGrade
            userSettings.hasCompletedOnboarding = true

            do {
                try modelContext.save()
            } catch {
                print("Failed to save onboarding settings: \(error)")
            }

            // 両方の学年の単語帳を読み込む（選択した学年をアクティブに）
            Task {
                await BuiltInDeckLoader.loadAllGradeDecks(
                    activeGrade: selectedGrade,
                    modelContext: modelContext
                )
            }
        }

        // 完了画面へ
        withAnimation {
            currentPage = .completion
        }
    }
}

// MARK: - Welcome Page

struct WelcomePageView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // アプリキャラクター
            Image("SplashImage")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .shadow(color: Color.rpPrimary.opacity(0.3), radius: 20, y: 10)

            VStack(spacing: 16) {
                Text("リピたんへようこそ！")
                    .font(.rpTitle)
                    .foregroundColor(.rpText)

                Text("英単語を楽しく覚えよう")
                    .font(.rpHeadline)
                    .foregroundColor(.rpTextSecondary)
            }

            // 特徴の説明
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "かしこく学習",
                    description: "忘れそうなタイミングで復習"
                )

                FeatureRow(
                    icon: "speaker.wave.2.fill",
                    title: "発音もバッチリ",
                    description: "ネイティブの発音を聞ける"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "成長を実感",
                    description: "毎日の学習を記録"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // 次へボタン
            Button(action: onNext) {
                HStack {
                    Text("はじめる")
                        .font(.rpHeadline)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.rpPrimary)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.rpPrimary)
                .frame(width: 44, height: 44)
                .background(Color.rpPrimary.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.rpBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.rpText)

                Text(description)
                    .font(.rpCaption)
                    .foregroundColor(.rpTextSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Grade Selection Page

struct GradeSelectionPageView: View {
    @Binding var selectedGrade: Int?
    let onNext: () -> Void
    let onBack: () -> Void

    /// 利用可能な学年（中1・中2・中3）
    private let availableGrades = [1, 2, 3]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // ヘッダー
            VStack(spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.rpPrimary)

                Text("何年生ですか？")
                    .font(.rpTitle)
                    .foregroundColor(.rpText)

                Text("学年に合わせた単語帳を用意します")
                    .font(.rpBody)
                    .foregroundColor(.rpTextSecondary)
            }

            // 学年選択（中1・中2のみ）
            VStack(spacing: 12) {
                ForEach(availableGrades, id: \.self) { grade in
                    GradeButton(
                        grade: grade,
                        isSelected: selectedGrade == grade,
                        action: { selectedGrade = grade }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Spacer()

            // ナビゲーションボタン
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("戻る")
                    }
                    .font(.rpBody)
                    .foregroundColor(.rpTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.rpTextSecondary.opacity(0.1))
                    .cornerRadius(16)
                }

                Button(action: onNext) {
                    HStack {
                        Text("完了")
                        Image(systemName: "checkmark")
                    }
                    .font(.rpHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedGrade != nil ? Color.rpPrimary : Color.rpTextSecondary)
                    .cornerRadius(16)
                }
                .disabled(selectedGrade == nil)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

struct GradeButton: View {
    let grade: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("中学\(grade)年生")
                    .font(.rpHeadline)
                    .foregroundColor(isSelected ? .white : .rpText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(isSelected ? Color.rpPrimary : Color.rpCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.rpBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Completion View

struct OnboardingCompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 成功アニメーション
            ZStack {
                Circle()
                    .fill(Color.rpSuccess.opacity(0.2))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.rpSuccess)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showConfetti ? 1.0 : 0.5)
            .opacity(showConfetti ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            VStack(spacing: 16) {
                Text("準備完了！")
                    .font(.rpLargeTitle)
                    .foregroundColor(.rpText)

                Text("さっそく英単語を覚えよう")
                    .font(.rpBody)
                    .foregroundColor(.rpTextSecondary)
            }

            // 選択内容の表示
            if let userSettings = settings.first {
                VStack(spacing: 12) {
                    if let grade = userSettings.selectedGrade {
                        SelectionSummaryRow(
                            icon: "graduationcap.fill",
                            label: "学年",
                            value: "中学\(grade)年生"
                        )
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // 学習開始ボタン
            Button(action: dismissOnboarding) {
                HStack {
                    Text("学習をはじめる")
                        .font(.rpHeadline)
                    Image(systemName: "play.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.rpPrimary)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }

    private func dismissOnboarding() {
        // すでにhasCompletedOnboardingはtrueになっているので
        // ContentViewが自動的にメイン画面を表示する
    }
}

struct SelectionSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.rpPrimary)
                .frame(width: 24)

            Text(label)
                .font(.rpBody)
                .foregroundColor(.rpTextSecondary)

            Spacer()

            Text(value)
                .font(.rpBody)
                .fontWeight(.semibold)
                .foregroundColor(.rpText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.rpCard)
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
