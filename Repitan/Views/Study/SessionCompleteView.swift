import SwiftUI
import SwiftData

/// セッション完了画面
struct SessionCompleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: StudySession
    /// TestViewを閉じるためのアクション
    let dismissTestView: DismissAction

    @State private var currentStreak: Int = 0
    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rpBackground.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // お祝いアイコン
                    VStack(spacing: 16) {
                        Text("🎉")
                            .font(.system(size: 64))
                            .scaleEffect(showConfetti ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showConfetti)

                        Text("今日の学習完了！")
                            .font(.rpTitle1)
                            .foregroundColor(.rpTextPrimary)
                    }

                    // 統計カード
                    VStack(spacing: 16) {
                        HStack(spacing: 32) {
                            StatBox(
                                value: "\(session.cardsStudied)",
                                label: "学習した単語",
                                icon: "book.fill"
                            )

                            StatBox(
                                value: "\(session.accuracyPercent)%",
                                label: "正答率",
                                icon: "checkmark.circle.fill"
                            )
                        }

                        HStack(spacing: 32) {
                            StatBox(
                                value: session.formattedDuration,
                                label: "学習時間",
                                icon: "clock.fill"
                            )

                            StatBox(
                                value: "\(currentStreak)",
                                label: "連続日数",
                                icon: "flame.fill"
                            )
                        }
                    }
                    .padding()
                    .rpCardStyle()
                    .padding(.horizontal)

                    // ストリーク表示
                    if currentStreak > 0 {
                        HStack(spacing: 8) {
                            Text("🔥")
                                .font(.system(size: 32))

                            Text("連続 \(currentStreak) 日目！")
                                .font(.rpTitle2)
                                .foregroundColor(.rpStreak)
                        }
                        .padding()
                        .background(Color.rpStreak.opacity(0.1))
                        .cornerRadius(16)
                    }

                    Spacer()

                    // ボタン
                    VStack(spacing: 12) {
                        Button {
                            // SessionCompleteViewを閉じてからTestViewも閉じる
                            dismiss()
                            dismissTestView()
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("ホームに戻る")
                            }
                        }
                        .buttonStyle(RPPrimaryButtonStyle())

                        Button {
                            // もう少し学習する：SessionCompleteViewだけ閉じてTestViewに戻る
                            dismiss()
                        } label: {
                            Text("もう少し学習する →")
                                .font(.rpBody)
                                .foregroundColor(.rpPrimary)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // キーボードを確実に閉じる（複数の方法を併用）
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                // 全てのウィンドウでendEditing
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            window.endEditing(true)
                        }
                    }
                }

                // 少し遅延させて再度実行（確実性のため）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    for scene in UIApplication.shared.connectedScenes {
                        if let windowScene = scene as? UIWindowScene {
                            for window in windowScene.windows {
                                window.endEditing(true)
                            }
                        }
                    }
                }

                loadStreak()
                withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                    showConfetti = true
                }
            }
        }
    }

    private func loadStreak() {
        let streakCalculator = StreakCalculator(modelContext: modelContext)
        currentStreak = streakCalculator.calculateCurrentStreak()
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.rpTitle3)
                .foregroundColor(.rpPrimary)

            Text(value)
                .font(.rpStatsNumber)
                .foregroundColor(.rpTextPrimary)

            Text(label)
                .font(.rpCaption1)
                .foregroundColor(.rpTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

private struct SessionCompletePreviewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    let session: StudySession

    var body: some View {
        SessionCompleteView(session: session, dismissTestView: dismiss)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StudySession.self, DailyStats.self, configurations: config)

    let session = StudySession(sessionType: .mixed)
    session.cardsStudied = 25
    session.correctCount = 21
    session.durationSeconds = 1080
    session.complete()
    container.mainContext.insert(session)

    return SessionCompletePreviewWrapper(session: session)
        .modelContainer(container)
}
