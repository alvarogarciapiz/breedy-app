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
                    
                    // Daily goal progress
                    dailyGoalSection
                    
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
                    
                    // Science insight
                    homeScienceTip
                    
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
                    
                    Text(personalizedSubtitle)
                        .font(BDDesign.Typography.bodyLarge)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                BreedyImageView(
                    imageName: homeBreedyImage,
                    size: 64,
                    auraColor: homeBreedyAura
                )
            }
        }
        .padding(.top, BDDesign.Spacing.lg)
    }
    
    private var personalizedSubtitle: String {
        let goal = appState.userGoal
        if !goal.isEmpty {
            switch appState.timeOfDay {
            case .morning:   return "Start your day with intention"
            case .afternoon: return "A mindful break to recenter"
            case .evening:   return "Wind down and find your calm"
            case .night:     return "Breathe into restful sleep"
            }
        }
        return "Ready to breathe?"
    }
    
    private var homeBreedyImage: String {
        if selectedMood != nil { return "breedy_breathe" }
        
        let goalMinutes = Double(appState.dailyGoalMinutes)
        let todayMin = stats?.todayMinutes ?? 0
        let isComplete = goalMinutes > 0 && todayMin >= goalMinutes
        
        switch appState.timeOfDay {
        case .night, .evening:
            return isComplete ? "breedy_happy_sleep" : "breedy_sleep"
        case .morning:   return "breedy_greet"
        case .afternoon: return "breedy_awake"
        }
    }
    
    private var homeBreedyAura: Color {
        switch appState.timeOfDay {
        case .night:     return BDDesign.Colors.accentSleep
        case .evening:   return BDDesign.Colors.accentSleep
        case .morning:   return Color(hex: 0xD9A05B) // Muted Gold
        case .afternoon: return BDDesign.Colors.accentCalm
        }
    }
    
    // MARK: - Daily Goal
    
    private var dailyGoalSection: some View {
        let goalMinutes = Double(appState.dailyGoalMinutes)
        let todayMin = stats?.todayMinutes ?? 0
        let progress = goalMinutes > 0 ? min(todayMin / goalMinutes, 1.0) : 0
        let isComplete = todayMin >= goalMinutes
        
        return HStack(spacing: BDDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "target")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isComplete ? Color(hex: 0x7F9F80) : BDDesign.Colors.accentCalm)
                    
                    Text(isComplete ? "Daily goal complete!" : "Daily Goal")
                        .font(BDDesign.Typography.cardTitle)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                }
                
                Text("\(Int(todayMin)) of \(appState.dailyGoalMinutes) min today")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : BDDesign.Colors.gray100)
                        Capsule()
                            .fill(
                                isComplete
                                    ? Color(hex: 0x7F9F80)
                                    : BDDesign.Colors.accentCalm
                            )
                            .frame(width: max(geo.size.width * progress, 4))
                    }
                }
                .frame(height: 5)
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
    
    // MARK: - Mood Selection
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("How do you want to feel?")
                .font(BDDesign.Typography.cardTitle)
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
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16))
                    Text("Quick Start")
                        .font(BDDesign.Typography.bodyMedium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [BDDesign.Colors.gray900, Color(hex: 0x1A1A1A)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                )
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
                Image(systemName: "arrow.triangle.2.circlepath")
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
    
    // MARK: - Science Tip
    
    private var homeScienceTip: some View {
        let tips: [(icon: String, text: String)] = [
            ("brain.fill", "Slow exhales increase parasympathetic tone via the vagus nerve, reducing systemic cortisol levels."),
            ("heart.fill", "Controlled respiration protocols improve Heart Rate Variability (HRV), a primary clinical biomarker for autonomic nervous system resilience."),
            ("lungs.fill", "Resonance frequency breathing (~5.5 breaths/min) synchronizes cardiovascular and respiratory rhythms, optimizing gas exchange."),
            ("figure.mind.and.body", "Consistent diaphragmatic breathing lowers baseline sympathetic arousal, mitigating chronic stress responses."),
            ("waveform.path", "Voluntary respiratory modulation directly influences cortical activity and emotional regulation pathways.")
        ]
        let tip = tips[Calendar.current.component(.hour, from: Date()) % tips.count]
        
        return HStack(alignment: .top, spacing: BDDesign.Spacing.sm) {
            Image(systemName: tip.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BDDesign.Colors.accentFocus)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Clinical Evidence")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.accentFocus)
                Text(tip.text)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                .fill(BDDesign.Colors.accentFocus.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                        .strokeBorder(BDDesign.Colors.accentFocus.opacity(0.12), lineWidth: 0.5)
                }
        }
    }
    
    // MARK: - Smart Suggestion
    
    private var smartSuggestion: some View {
        Group {
            let pattern = suggestedPatternForTime()
            VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0xD9A05B))
                    Text("Clinical Protocol")
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
        case .morning:   return BreathingPresets.kapalabhati
        case .afternoon: return BreathingPresets.boxBreathing
        case .evening:   return BreathingPresets.coherentBreathing
        case .night:     return BreathingPresets.fourSevenEight
        }
    }
    
    private var smartSuggestionText: String {
        let goal = appState.userGoal
        if goal == "Reduce Stress" || goal == "Manage Anxiety" {
            return "Personalized protocol for nervous system down-regulation"
        } else if goal == "Improve Focus" {
            return "Protocol for sympathetic arousal and cognitive focus"
        } else if goal == "Better Sleep" {
            return "Protocol for parasympathetic dominance and sleep preparation"
        }
        switch appState.timeOfDay {
        case .morning:   return "Morning protocol for metabolic activation"
        case .afternoon: return "Midday protocol for cognitive resilience"
        case .evening:   return "Evening protocol for stress reduction"
        case .night:     return "Nighttime protocol for deep sleep induction"
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .environment(StatsManager())
}
