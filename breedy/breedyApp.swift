import SwiftUI
import SwiftData

@main
struct BreedyApp: App {
    
    @State private var appState = AppState()
    @State private var statsManager = StatsManager()
    @State private var subscriptionManager = SubscriptionManager()
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    
    init() {
        if let largeDescriptor = UIFont.systemFont(ofSize: 34, weight: .regular).fontDescriptor.withDesign(.serif),
           let inlineDescriptor = UIFont.systemFont(ofSize: 17, weight: .medium).fontDescriptor.withDesign(.serif) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(descriptor: largeDescriptor, size: 34)]
            UINavigationBar.appearance().titleTextAttributes = [.font: UIFont(descriptor: inlineDescriptor, size: 17)]
        }
    }
    
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
    
    var colorSchemeOverride: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(statsManager)
                .environment(subscriptionManager)
                .onAppear {
                    statsManager.configure(
                        modelContext: sharedModelContainer.mainContext
                    )
                }
                .preferredColorScheme(colorSchemeOverride)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("isSubscribed") private var isSubscribed = false
    @AppStorage("privacyMode") private var privacyMode = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if !isSubscribed {
                PaywallView()
            } else {
                MainTabView()
            }
        }
        .blur(radius: privacyMode && scenePhase != .active ? 20 : 0)
        .overlay {
            if privacyMode && scenePhase != .active {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scenePhase)
    }
}
