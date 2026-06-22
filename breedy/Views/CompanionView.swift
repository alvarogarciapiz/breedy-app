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
    @State private var unlockedBadges: Set<String> = []
    @State private var dailyQuests: [DailyQuestRecord] = []
    @AppStorage("equippedAuraId") private var equippedAuraId = "default"
    
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
                    
                    // Streak Banner
                    if (stats?.currentStreak ?? 0) > 0 {
                        streakBanner
                    }
                    
                    // Message bubble
                    messageBubble
                    
                    // Daily check-in
                    if !hasCheckedIn {
                        if showCheckIn {
                            checkInForm
                        } else {
                            checkInPrompt
                        }
                    } else {
                        checkInSummary
                    }
                    
                    // Daily Quests
                    if !dailyQuests.isEmpty {
                        dailyQuestsSection
                    }
                    
                    // Suggested session
                    suggestedSession
                    
                    // XP Progress
                    xpProgressSection
                    
                    // Auras
                    aurasSection
                    
                    // Milestones (Badges)
                    milestonesSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Companion")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: Bindable(statsManager).showLevelUp) {
                LevelUpView(newLevel: statsManager.newLevelReached ?? 2)
            }
        }
        .onAppear {
            refreshData()
        }
    }
    
    // MARK: - Mascot Hero
    
    private var mascotHero: some View {
        VStack(spacing: BDDesign.Spacing.lg) {
            BreedyImageView(
                imageName: companionImageName,
                size: 160,
                auraColor: companionAuraColor
            )
            
            VStack(spacing: 4) {
                Text("Breedy")
                    .font(BDDesign.Typography.sectionHeading)
                    .tracking(-1.28)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BDDesign.Colors.accentAnxiety.opacity(0.6))
                    Text("Clinical Biofeedback Assistant")
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
        }
        .padding(.top, BDDesign.Spacing.lg)
    }
    
    private var companionImageName: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 { return "breedy_sleep" }
        if let s = stats, s.currentStreak >= 7 { return "breedy_greet" }
        return "breedy_awake"
    }
    
    private var companionAuraColor: Color {
        let defaultColor = BDDesign.Colors.accentCalm
        guard let aura = CompanionAuras.allAuras.first(where: { $0.id == equippedAuraId }) else {
            return defaultColor
        }
        return Color(hex: aura.colorHex)
    }
    
    // MARK: - Message Bubble
    
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            HStack(spacing: BDDesign.Spacing.sm) {
                Text("📋")
                Text("Clinical Assistant")
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
    
    // MARK: - Streak Banner
    
    private var streakBanner: some View {
        let streak = stats?.currentStreak ?? 0
        
        return HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.orange)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) Day Streak!")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Text("You're on fire! Keep it up.")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            Spacer()
        }
        .padding(BDDesign.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
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
                    Text("Symptom Assessment")
                        .font(BDDesign.Typography.bodySemibold)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text("Log current physiological state")
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
            Text("Clinical Biofeedback Assessment")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            checkInSlider("Cortisol / Stress Index", value: $stressLevel, low: "Optimal", high: "Elevated", color: BDDesign.Colors.accentAnxiety)
            checkInSlider("Valence / Mood State", value: $moodLevel, low: "Depressed", high: "Elevated", color: BDDesign.Colors.accentCalm)
            checkInSlider("Metabolic Energy", value: $energyLevel, low: "Depleted", high: "Optimal", color: BDDesign.Colors.accentEnergy)
            checkInSlider("Sleep Architecture", value: $sleepQuality, low: "Fragmented", high: "Restorative", color: BDDesign.Colors.accentSleep)
            
            Button {
                saveCheckIn()
            } label: {
                Text("Submit")
                    .bdPrimaryButton()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    // MARK: - Check-in Summary
    
    private var checkInSummary: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(BDDesign.Colors.accentEnergy)
                Text("Biometric Insight")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            }
            
            Text(statsManager.generateBiometricInsight())
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray500)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
    
    // MARK: - XP Progress
    
    private var xpProgressSection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            let level = stats?.level ?? 1
            let totalXP = stats?.totalXP ?? 0
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clinical Phase \(level)")
                        .font(BDDesign.Typography.cardTitle)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text(relationshipTitle(level: level))
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalXP) NP")
                        .font(BDDesign.Typography.cardTitle)
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                    Text("Neuroplasticity")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            
            // XP Progress bar
            let xpInfo = statsManager.xpForNextLevel(currentXP: totalXP)
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : BDDesign.Colors.gray100)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [BDDesign.Colors.accentCalm, BDDesign.Colors.accentFocus],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: xpInfo.needed > 0 ? geo.size.width * CGFloat(xpInfo.current) / CGFloat(xpInfo.needed) : 0)
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
                
                HStack {
                    Text("\(xpInfo.current) / \(xpInfo.needed) NP")
                        .font(BDDesign.Typography.captionMedium)
                        .foregroundStyle(BDDesign.Colors.gray500)
                    Spacer()
                    Text("Next phase")
                        .font(BDDesign.Typography.captionMedium)
                        .foregroundStyle(BDDesign.Colors.gray400)
                }
            }
            .padding(.top, BDDesign.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Auras Section
    
    private var aurasSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Resonance Modes")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            let level = stats?.level ?? 1
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BDDesign.Spacing.md) {
                    ForEach(CompanionAuras.allAuras) { aura in
                        let isUnlocked = level >= aura.requiredLevel
                        let isEquipped = equippedAuraId == aura.id
                        
                        Button {
                            if isUnlocked {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    equippedAuraId = aura.id
                                    HapticsManager.shared.selection()
                                }
                            }
                        } label: {
                            VStack(spacing: BDDesign.Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: aura.colorHex))
                                        .frame(width: 56, height: 56)
                                        .opacity(isUnlocked ? 1 : 0.3)
                                        .shadow(color: isEquipped ? Color(hex: aura.colorHex).opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                                    
                                    if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    } else if isEquipped {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                                    }
                                }
                                
                                VStack(spacing: 2) {
                                    Text(aura.title)
                                        .font(BDDesign.Typography.captionMedium)
                                        .foregroundStyle(isUnlocked ? (colorScheme == .dark ? .white : BDDesign.Colors.gray900) : BDDesign.Colors.gray400)
                                    
                                    Text(isUnlocked ? "" : "Phase \(aura.requiredLevel)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(BDDesign.Colors.gray500)
                                }
                            }
                            .padding(.vertical, BDDesign.Spacing.sm)
                            .padding(.horizontal, BDDesign.Spacing.xs)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isUnlocked)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, BDDesign.Spacing.sm)
    }
    
    // MARK: - Milestones
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Biometric Achievements")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                Text("\(unlockedBadges.count)/\(BadgeDefinition.allBadges.count)")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BDDesign.Spacing.sm) {
                ForEach(BadgeDefinition.allBadges) { badge in
                    BadgeCardView(
                        badge: badge,
                        isUnlocked: unlockedBadges.contains(badge.id)
                    )
                }
            }
        }
    }
    
    // MARK: - Daily Quests Section
    
    private var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Daily Care Plan")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                Text("\(dailyQuests.filter { $0.isCompleted }.count)/\(dailyQuests.count)")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            VStack(spacing: BDDesign.Spacing.sm) {
                ForEach(dailyQuests, id: \.id) { quest in
                    HStack(spacing: BDDesign.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(quest.isCompleted ? BDDesign.Colors.accentCalm : BDDesign.Colors.gray100)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: quest.isCompleted ? "checkmark" : quest.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(quest.isCompleted ? .white : BDDesign.Colors.gray400)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quest.title)
                                .font(BDDesign.Typography.bodySemibold)
                                .foregroundStyle(quest.isCompleted ? BDDesign.Colors.gray400 : (colorScheme == .dark ? .white : BDDesign.Colors.gray900))
                                .strikethrough(quest.isCompleted)
                            
                            Text(quest.descriptionText)
                                .font(BDDesign.Typography.caption)
                                .foregroundStyle(BDDesign.Colors.gray500)
                        }
                        
                        Spacer()
                        
                        Text("+\(quest.xpReward) NP")
                            .font(BDDesign.Typography.captionMedium)
                            .foregroundStyle(quest.isCompleted ? BDDesign.Colors.gray400 : BDDesign.Colors.accentEnergy)
                    }
                    .padding(BDDesign.Spacing.sm)
                    .bdCard()
                    .opacity(quest.isCompleted ? 0.7 : 1.0)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        stats = statsManager.computeStats()
        unlockedBadges = statsManager.fetchUnlockedBadgeIds()
        dailyQuests = statsManager.fetchDailyQuests()
        checkTodaysCheckIn()
        generateMessage()
    }
    
    private func generateMessage() {
        let messages: [String]
        let hour = Calendar.current.component(.hour, from: Date())
        let streak = stats?.currentStreak ?? 0
        
        if hour >= 22 || hour < 6 {
            messages = [
                "Circadian rhythm indicates nighttime. Commencing parasympathetic down-regulation.",
                "Cortisol suppression recommended. Initiate deep breathing protocols for sleep induction.",
                "Optimizing overnight heart rate variability. Proceed with respiratory modulation."
            ]
        } else if streak >= 7 {
            messages = [
                "Physiological adaptation confirmed: \(streak) consecutive days of active regulation.",
                "Neurological pathways demonstrating sustained plasticity and resilience.",
                "Consistent biofeedback loop maintained. Autonomic balance is stabilizing."
            ]
        } else if streak == 0 {
            messages = [
                "System ready for respiratory intervention. Awaiting protocol selection.",
                "Baseline metrics acquired. Ready to initiate down-regulation sequence.",
                "Clinical assistant standing by for physiological modulation."
            ]
        } else {
            messages = [
                "Adherence verified. \(streak)-day protocol continuity detected.",
                "Returning to baseline. Please engage a session to maintain autonomic balance.",
                "Routine physiological maintenance required. Select an active protocol."
            ]
        }
        
        companionMessage = messages.randomElement() ?? messages[0]
    }
    
    private func recommendedPattern() -> BreathingPattern {
        if stressLevel >= 4 {
            return BreathingPresets.physiologicalSigh
        } else if energyLevel <= 2 {
            return BreathingPresets.kapalabhati
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
            companionMessage = "Sympathetic nervous system arousal detected. Commencing down-regulation protocol."
        } else if moodLevel >= 4 && energyLevel >= 4 {
            companionMessage = "Optimal physiological homeostasis achieved. Continue maintenance."
        } else {
            companionMessage = "Biometrics logged. Adjusting neuro-respiratory recommendations accordingly."
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
// MARK: - Badge Card

struct BadgeCardView: View {
    let badge: BadgeDefinition
    let isUnlocked: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let accent = tierColor(for: badge.tier)
        
        VStack(spacing: BDDesign.Spacing.sm) {
            Image(systemName: badge.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isUnlocked ? accent : BDDesign.Colors.gray400)
                .opacity(isUnlocked ? 1 : 0.4)
            
            Text(badge.title)
                .font(BDDesign.Typography.captionMedium)
                .foregroundStyle(isUnlocked ? (colorScheme == .dark ? .white : BDDesign.Colors.gray900) : BDDesign.Colors.gray400)
                .multilineTextAlignment(.center)
            
            Text(isUnlocked ? "+\(badge.xpReward) XP" : badge.requirement)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(isUnlocked ? accent : BDDesign.Colors.gray400)
        }
        .frame(maxWidth: .infinity)
        .padding(BDDesign.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : .white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked && badge.tier == .legendary ? accent.opacity(0.5) : Color.clear, lineWidth: 2)
        }
        .shadow(color: isUnlocked && badge.tier == .legendary ? accent.opacity(0.2) : .clear, radius: 10, x: 0, y: 5)
        .opacity(isUnlocked ? 1 : 0.6)
    }
    
    private func tierColor(for tier: BadgeTier) -> Color {
        switch tier {
        case .common: return BDDesign.Colors.accentCalm
        case .rare: return BDDesign.Colors.accentFocus
        case .epic: return BDDesign.Colors.accentEnergy
        case .legendary: return Color(hex: 0xFFD700)
        }
    }
}

#Preview {
    CompanionView()
        .environment(AppState())
        .environment(StatsManager())
}
