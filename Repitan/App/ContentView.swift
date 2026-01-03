import SwiftUI
import SwiftData

/// メインコンテンツビュー
/// TabViewでホーム、カード管理、設定を切り替え
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "ホーム"
        case cards = "カード"
        case settings = "設定"

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .cards: return "rectangle.stack.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    /// オンボーディングが完了しているか
    private var hasCompletedOnboarding: Bool {
        settings.first?.hasCompletedOnboarding ?? false
    }

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView()
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.iconName)
                }
                .tag(Tab.home)

            CardsView()
                .tabItem {
                    Label(Tab.cards.rawValue, systemImage: Tab.cards.iconName)
                }
                .tag(Tab.cards)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .tint(.rpPrimary)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            Deck.self,
            Card.self,
            ReviewHistory.self,
            StudySession.self,
            DailyStats.self,
            UserSettings.self,
            Achievement.self,
        ], inMemory: true)
}
