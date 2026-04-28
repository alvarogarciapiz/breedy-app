import SwiftUI

// MARK: - Companion View

struct CompanionView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var stats: UserStats?
    @State private var hasCheckedIn = false
    @State private var showCheckIn = false
    @State private var companionMessage = ""
    @State private var animateMessage = false
    
    // Check-in state
    @State private var stressLevel: Int = 3
    @State private var moodLevel: Int = 3
    @State private var energyLevel: Int = 3
    @State private var sleepQuality: Int = 3
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Mascot hero
                    mascotHero
                    
                    // Message bubble
                    messageBubble
                    
                    // Daily check-in
                    if !hasCheckedIn {
                        checkInPrompt
                    } else if showCheckIn {
                        checkInForm
                    }
                    
                    // Suggested session
                    suggestedSession
                    
                    // Relationship progress
                    relationshipSection
                    
                    // Unlockables
                    unlockablesSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Companion")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            stats = statsManager.computeStats()
            checkTodaysCheckIn()
            generateMessage()
        }
    }
    
    // MARK: - Mascot Hero
    
    private var mascotHero: some View {
        VStack(spacing: BDDesign.Spacing.lg) {
            BreedyMascotView(
                mood: companionMood,
                size: 140
            )
            
            Text("Breedy")
                .font(BDDesign.Typography.sectionHeading)
                .tracking(-1.28)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            Text("Your breathing companion")
                .font(BDDesign.Typography.bodySmall)
                .foregroundStyle(BDDesign.Colors.gray500)
        }
        .padding(.top, BDDesign.Spacing.lg)
    }
    
    // MARK: - Message Bubble
    
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            HStack(spacing: BDDesign.Spacing.sm) {
                Text("💬")
                Text("Breedy says")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            Text(companionMessage)
                .font(BDDesign.Typography.body)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                .opacity(animateMessage ? 1 : 0)
                .offset(y: animateMessage ? 0 : 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
        .onAppear {
            withAnimation(BDDesign.Motion.slow.delay(0.3)) {
                animateMessage = true
            }
        }
    }
    
    // MARK: - Check-in Prompt
    
    private var checkInPrompt: some View {
        Button {
            withAnimation(BDDesign.Motion.standard) {
                showCheckIn = true
            }
        } label: {
            HStack(spacing: BDDesign.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(BDDesign.Colors.accentCalm.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Check-in")
                        .font(BDDesign.Typography.bodySemibold)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text("How are you feeling today?")
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
    
    // MARK: - Check-in Form
    
    private var checkInForm: some View {
        VStack(spacing: BDDesign.Spacing.lg) {
            Text("How are you right now?")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            checkInSlider("Stress Level", value: $stressLevel, low: "Low", high: "High", color: BDDesign.Colors.accentAnxiety)
            checkInSlider("Mood", value: $moodLevel, low: "Low", high: "Great", color: BDDesign.Colors.accentCalm)
            checkInSlider("Energy", value: $energyLevel, low: "Tired", high: "Energized", color: BDDesign.Colors.accentEnergy)
            checkInSlider("Sleep Quality", value: $sleepQuality, low: "Poor", high: "Excellent", color: BDDesign.Colors.accentSleep)
            
            Button {
                saveCheckIn()
            } label: {
                Text("Submit")
                    .bdPrimaryButton()
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func checkInSlider(_ title: String, value: Binding<Int>, low: String, high: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                Spacer()
                Text(levelEmoji(value.wrappedValue))
                    .font(.system(size: 20))
            }
            
            HStack(spacing: BDDesign.Spacing.sm) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        value.wrappedValue = level
                        HapticsManager.shared.selection()
                    } label: {
                        Circle()
                            .fill(level <= value.wrappedValue ? color : color.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("\(level)")
                                    .font(BDDesign.Typography.captionMedium)
                                    .foregroundStyle(level <= value.wrappedValue ? .white : color)
                            }
                    }
                }
            }
            
            HStack {
                Text(low)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray400)
                Spacer()
                Text(high)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray400)
            }
        }
    }
    
    // MARK: - Suggested Session
    
    private var suggestedSession: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Recommended for you")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                Text("Based on mood")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            let pattern = recommendedPattern()
            SessionCardView(pattern: pattern) {
                appState.startSession(pattern: pattern)
            }
        }
    }
    
    // MARK: - Relationship
    
    private var relationshipSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Your Bond with Breedy")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            let level = stats?.level ?? 1
            
            HStack(spacing: BDDesign.Spacing.lg) {
                VStack(spacing: 4) {
                    Text("Level \(level)")
                        .font(BDDesign.Typography.subheadingLarge)
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                    Text(relationshipTitle(level: level))
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(stats?.totalSessions ?? 0)")
                        .font(BDDesign.Typography.cardTitle)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text("sessions together")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            .padding(BDDesign.Spacing.lg)
            .bdCard()
        }
    }
    
    // MARK: - Unlockables
    
    private var unlockablesSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Unlockables")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            let level = stats?.level ?? 1
            
            ForEach(CompanionUnlockables.expressions) { unlockable in
                let isUnlocked = level >= unlockable.requiredLevel
                
                HStack(spacing: BDDesign.Spacing.md) {
                    Text(unlockable.icon)
                        .font(.system(size: 24))
                        .opacity(isUnlocked ? 1 : 0.3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(unlockable.title)
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(isUnlocked ? (colorScheme == .dark ? .white : BDDesign.Colors.gray900) : BDDesign.Colors.gray400)
                        
                        Text(isUnlocked ? unlockable.description : "Reach level \(unlockable.requiredLevel)")
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    
                    Spacer()
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(BDDesign.Colors.accentCalm)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(BDDesign.Colors.gray400)
                    }
                }
                .padding(BDDesign.Spacing.md)
                .bdCard()
                .opacity(isUnlocked ? 1 : 0.65)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var companionMood: MascotMood {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 { return .sleepy }
        if let s = stats, s.currentStreak >= 7 { return .celebrating }
        return .happy
    }
    
    private func generateMessage() {
        let messages: [String]
        let hour = Calendar.current.component(.hour, from: Date())
        let streak = stats?.currentStreak ?? 0
        
        if hour >= 22 || hour < 6 {
            messages = [
                "It's getting late. A few deep breaths can help you drift off peacefully.",
                "The world is quiet now. Perfect time for a calming breath.",
                "Rest well tonight. Your breathing practice is making you stronger."
            ]
        } else if streak >= 7 {
            messages = [
                "Amazing! \(streak) days in a row. You're building something beautiful.",
                "Your dedication inspires me. Let's keep this flow going!",
                "You've been so consistent. I'm proud of our journey together."
            ]
        } else if streak == 0 {
            messages = [
                "Hey there! Ready to start something great today?",
                "Every breath is a fresh start. Let's begin together.",
                "I'm here whenever you need me. No pressure, just support."
            ]
        } else {
            messages = [
                "Welcome back! Your \(streak)-day streak is looking strong.",
                "Great to see you again. How about a quick breathing session?",
                "You're doing wonderful. Consistency is your superpower."
            ]
        }
        
        companionMessage = messages.randomElement() ?? messages[0]
    }
    
    private func recommendedPattern() -> BreathingPattern {
        if stressLevel >= 4 {
            return BreathingPresets.anxietyReset
        } else if energyLevel <= 2 {
            return BreathingPresets.energyBreath
        } else if sleepQuality <= 2 {
            return BreathingPresets.fourSevenEight
        } else {
            return BreathingPresets.coherentBreathing
        }
    }
    
    private func checkTodaysCheckIn() {
        hasCheckedIn = statsManager.todayCheckIn() != nil
    }
    
    private func saveCheckIn() {
        let checkIn = DailyCheckIn(
            stressLevel: stressLevel,
            moodLevel: moodLevel,
            energyLevel: energyLevel,
            sleepQuality: sleepQuality
        )
        statsManager.saveCheckIn(checkIn)
        
        withAnimation(BDDesign.Motion.standard) {
            hasCheckedIn = true
            showCheckIn = false
        }
        
        // Update message based on check-in
        if stressLevel >= 4 {
            companionMessage = "I can see you're feeling stressed. Let's breathe through it together. You've got this. 💙"
        } else if moodLevel >= 4 && energyLevel >= 4 {
            companionMessage = "You're in great shape today! Let's keep that positive energy flowing. ✨"
        } else {
            companionMessage = "Thanks for checking in. Remember, every breath brings you closer to balance."
        }
        
        HapticsManager.shared.milestone()
    }
    
    private func levelEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😔"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }
    
    private func relationshipTitle(level: Int) -> String {
        switch level {
        case 1: return "New Friends"
        case 2: return "Breathing Buddies"
        case 3: return "Trusted Companions"
        case 4...5: return "Soul Partners"
        case 6...8: return "Zen Masters"
        default: return "Legendary Bond"
        }
    }
}

#Preview {
    CompanionView()
        .environment(AppState())
        .environment(StatsManager())
}
