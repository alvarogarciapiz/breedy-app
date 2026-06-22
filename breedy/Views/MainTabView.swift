import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        @Bindable var state = appState
        
        TabView(selection: $state.selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }
            
            Tab("Sessions", systemImage: "wind", value: .sessions) {
                SessionsView()
            }
            
            Tab("Progress", systemImage: "chart.xyaxis.line", value: .progress) {
                ProgressView_()
            }
            
            Tab("Companion", systemImage: "sparkles", value: .companion) {
                CompanionView()
            }
            
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tint(.primary)
        .fullScreenCover(isPresented: $state.showSession) {
            if let pattern = appState.activePattern {
                BreathingSessionView(
                    pattern: pattern,
                    mood: appState.activeMood,
                    onComplete: { duration, cycles, completed in
                        _ = statsManager.recordSession(
                            pattern: pattern,
                            durationSeconds: duration,
                            completedCycles: cycles,
                            wasCompleted: completed
                        )
                        
                        // Write to Apple Health
                        Task {
                            let start = Date().addingTimeInterval(-Double(duration))
                            _ = await HealthManager.shared.saveMindfulSession(
                                startDate: start,
                                endDate: Date()
                            )
                        }
                    },
                    onDismiss: {
                        appState.endSession()
                    }
                )
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(StatsManager())
}
