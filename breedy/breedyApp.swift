import SwiftUI
import SwiftData

@main
struct BreedyApp: App {
    
    @State private var appState = AppState()
    @State private var statsManager = StatsManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SessionRecord.self,
            DailyCheckIn.self,
            BadgeRecord.self,
            CustomPatternRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(statsManager)
                .onAppear {
                    statsManager.configure(
                        modelContext: sharedModelContainer.mainContext
                    )
                }
                .preferredColorScheme(appState.colorSchemeOverride)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        if appState.hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
