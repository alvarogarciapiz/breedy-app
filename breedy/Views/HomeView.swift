import SwiftUI
import SwiftData

// MARK: - Home View

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedMood: MoodState?
    @State private var stats: UserStats?
    @State private var lastSession: SessionRecord?
    @State private var showQuickStart = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Header with greeting + mascot
                    headerSection
                    
                    // Mood selector
                    moodSection
                    
                    // Quick start / recommended
                    if let mood = selectedMood {
                        recommendedSection(for: mood)
                    } else {
                        quickStartSection
                    }
                    
                    // Stats row
                    statsRow
                    
                    // Resume last session
                    if let last = lastSession {
                        resumeSection(session: last)
                    }
                    
                    // Streak
                    streakSection
                    
                    // Smart suggestion
                    smartSuggestion
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { refreshData() }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: BDDesign.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(appState.greeting) \(appState.greetingEmoji)")
                        .font(BDDesign.Typography.sectionHeading)
                        .tracking(-1.28)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text("Ready to breathe?")
                        .font(BDDesign.Typography.bodyLarge)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                BreedyMascotView(
                    mood: selectedMood != nil
                        ? moodToMascotMood(selectedMood!)
                        : appState.timeOfDay.mascotMood,
                    size: 64
                )
            }
        }
        .padding(.top, BDDesign.Spacing.lg)
    }
    
    // MARK: - Mood Selection
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("How do you want to feel?")
                .font(BDDesign.Typography.bodySemibold)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BDDesign.Spacing.sm) {
                    ForEach(MoodState.allCases) { mood in
                        MoodChipView(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            action: {
                                HapticsManager.shared.selection()
                                withAnimation(BDDesign.Motion.standard) {
                                    selectedMood = selectedMood == mood ? nil : mood
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Recommended Section
    
    private func recommendedSection(for mood: MoodState) -> some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text(mood.greeting)
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                Text("Recommended")
                    .bdPillBadge(
                        background: mood.color.opacity(0.12),
                        text: mood.color
                    )
            }
            
            ForEach(BreathingPresets.presetsFor(mood: mood), id: \.id) { pattern in
                SessionCardView(pattern: pattern) {
                    HapticsManager.shared.tap()
                    appState.startSession(pattern: pattern, mood: mood)
                }
            }
        }
    }
    
    // MARK: - Quick Start
    
    private var quickStartSection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            // Quick start button
            Button {
                HapticsManager.shared.sessionStart()
                appState.startSession(pattern: BreathingPresets.coherentBreathing)
            } label: {
                HStack(spacing: BDDesign.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                    Text("Quick Start")
                        .font(BDDesign.Typography.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(BDDesign.Colors.gray900, in: RoundedRectangle(cornerRadius: BDDesign.Radius.standard))
            }
            
            // Featured session
            SessionCardView(pattern: suggestedPatternForTime()) {
                HapticsManager.shared.tap()
                appState.startSession(pattern: suggestedPatternForTime())
            }
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: BDDesign.Spacing.sm) {
            StatTileView(
                title: "Today",
                value: "\(Int(stats?.todayMinutes ?? 0)) min",
                icon: "clock.fill",
                accentColor: BDDesign.Colors.accentCalm
            )
            
            StatTileView(
                title: "Sessions",
                value: "\(stats?.todaySessions ?? 0)",
                icon: "wind",
                accentColor: BDDesign.Colors.accentFocus
            )
        }
    }
    
    // MARK: - Resume
    
    private func resumeSection(session: SessionRecord) -> some View {
        Button {
            if let pattern = BreathingPresets.allPresets.first(where: { $0.title == session.patternTitle }) {
                appState.startSession(pattern: pattern)
            }
        } label: {
            HStack(spacing: BDDesign.Spacing.md) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BDDesign.Colors.accentCalm)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume: \(session.patternTitle)")
                        .font(BDDesign.Typography.bodyMedium)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text(session.startedAt.formatted(.relative(presentation: .named)))
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BDDesign.Colors.gray400)
            }
            .padding(BDDesign.Spacing.md)
            .bdCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Streak
    
    private var streakSection: some View {
        StreakBadgeView(streak: stats?.currentStreak ?? 0)
    }
    
    // MARK: - Smart Suggestion
    
    private var smartSuggestion: some View {
        Group {
            let pattern = suggestedPatternForTime()
            VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0xFFD700))
                    Text("Smart suggestion")
                        .font(BDDesign.Typography.captionMedium)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Text(smartSuggestionText)
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray600)
                
                SessionCardView(pattern: pattern) {
                    appState.startSession(pattern: pattern)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        stats = statsManager.computeStats()
        lastSession = statsManager.fetchLastSession()
    }
    
    private func moodToMascotMood(_ mood: MoodState) -> MascotMood {
        switch mood {
        case .calm:          return .calm
        case .focus:         return .meditating
        case .sleep:         return .sleepy
        case .energy:        return .energetic
        case .anxietyRelief: return .supportive
        }
    }
    
    private func suggestedPatternForTime() -> BreathingPattern {
        switch appState.timeOfDay {
        case .morning:   return BreathingPresets.energyBreath
        case .afternoon: return BreathingPresets.boxBreathing
        case .evening:   return BreathingPresets.deepCalm
        case .night:     return BreathingPresets.fourSevenEight
        }
    }
    
    private var smartSuggestionText: String {
        switch appState.timeOfDay {
        case .morning:   return "Start your day with energizing breaths"
        case .afternoon: return "A quick breathing break to sharpen focus"
        case .evening:   return "Wind down with calming deep breaths"
        case .night:     return "Prepare for restful sleep"
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .environment(StatsManager())
}
