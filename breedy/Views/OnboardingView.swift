import SwiftUI

// MARK: - Onboarding View (6-Step Premium Flow)

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage = 0
    @State private var selectedGoal: OnboardingGoal?
    @State private var selectedExperience: ExperienceLevel?
    @State private var selectedTimes: Set<PreferredTime> = []
    @State private var dailyMinutes: Int = 5
    @State private var userName: String = ""
    @State private var reminderEnabled = true
    @State private var showPersonalPlan = false
    @State private var planRevealed = false
    @State private var planGenerationState: PlanGenerationState = .idle
    @AppStorage("healthKitEnabled") private var healthKitEnabled = false
    
    private let totalPages = 7
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: 0x0A0A0A) : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar: back + progress
                topBar
                
                // Pages
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    namePage.tag(1)
                    goalPage.tag(2)
                    experiencePage.tag(3)
                    timesPage.tag(4)
                    healthPage.tag(5)
                    personalPlanPage.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(BDDesign.Motion.standard, value: currentPage)
                .onChange(of: currentPage) { _, newPage in
                    if newPage == totalPages - 1 && planGenerationState == .idle {
                        startGenerationSequence()
                    }
                }
                
                // Continue button
                continueButton
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: BDDesign.Spacing.md) {
            // Back
            if currentPage > 0 {
                Button {
                    withAnimation(BDDesign.Motion.standard) { currentPage -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(BDDesign.Colors.gray500)
                        .padding(8)
                }
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : BDDesign.Colors.gray100)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [BDDesign.Colors.accentCalm, BDDesign.Colors.accentFocus],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(totalPages))
                        .animation(BDDesign.Motion.standard, value: currentPage)
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())
            
            // Step counter
            Text("\(currentPage + 1)/\(totalPages)")
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray400)
                .frame(width: 32)
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
        .padding(.top, BDDesign.Spacing.md)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Group {
            if currentPage == totalPages - 1 && planGenerationState != .ready {
                Color.clear.frame(height: 56)
                    .padding(.horizontal, BDDesign.Spacing.lg)
                    .padding(.bottom, BDDesign.Spacing.xl)
            } else {
                Button { advance() } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == totalPages - 1 ? "Start My Journey" : "Continue")
                            .font(BDDesign.Typography.bodyMedium)
                        if currentPage < totalPages - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                            .fill(canAdvance ? BDDesign.Colors.gray900 : BDDesign.Colors.gray400)
                    )
                }
                .disabled(!canAdvance)
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.xl)
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            // Animated mascot
            BreedyImageView(imageName: "breedy_greet", size: 180, auraColor: BDDesign.Colors.accentCalm)
                .padding(.bottom, BDDesign.Spacing.sm)
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Breathe. Focus.\nThrive.")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("Science-backed breathing exercises\npersonalized just for you.")
                    .font(BDDesign.Typography.bodyLarge)
                    .foregroundStyle(BDDesign.Colors.gray500)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Premium badges
            HStack(spacing: BDDesign.Spacing.sm) {
                premiumBadge("Science-backed", icon: "brain.fill")
                premiumBadge("100% Private", icon: "lock.fill")
                premiumBadge("Offline", icon: "wifi.slash")
            }
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func premiumBadge(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(BDDesign.Typography.caption)
        }
        .foregroundStyle(BDDesign.Colors.badgeBlueText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(BDDesign.Colors.badgeBlueBg, in: Capsule())
    }
    
    // MARK: - Page 2: Name
    
    private var namePage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            BreedyImageView(imageName: "breedy_awake", size: 100, auraColor: Color(hex: 0x4CAF50))
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("What should\nBreedy call you?")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("Optional — you can skip this")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            TextField("Your name", text: $userName)
                .font(BDDesign.Typography.bodyLarge)
                .multilineTextAlignment(.center)
                .padding(BDDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50)
                        .overlay {
                            RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                        }
                )
                .padding(.horizontal, BDDesign.Spacing.xl)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    // MARK: - Page 3: Goal
    
    private var goalPage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("What brings\nyou here?")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("This helps Breedy personalize your experience")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            VStack(spacing: BDDesign.Spacing.sm) {
                ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                    goalRow(goal)
                }
            }
            .padding(.horizontal, BDDesign.Spacing.sm)
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func goalRow(_ goal: OnboardingGoal) -> some View {
        Button {
            selectedGoal = goal
            HapticsManager.shared.selection()
        } label: {
            HStack(spacing: BDDesign.Spacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(selectedGoal == goal ? .white : goal.color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(selectedGoal == goal ? goal.color : goal.color.opacity(0.12))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(BDDesign.Typography.bodyMedium)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text(goal.subtitle)
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                if selectedGoal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(goal.color)
                }
            }
            .padding(BDDesign.Spacing.md)
            .bdCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Page 4: Experience
    
    private var experiencePage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            BreedyImageView(imageName: "breedy_breathe", size: 100, auraColor: BDDesign.Colors.accentCalm)
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Your breathing\nexperience")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("We'll adjust sessions to match your level")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            VStack(spacing: BDDesign.Spacing.sm) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    experienceRow(level)
                }
            }
            .padding(.horizontal, BDDesign.Spacing.sm)
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func experienceRow(_ level: ExperienceLevel) -> some View {
        Button {
            selectedExperience = level
            HapticsManager.shared.selection()
        } label: {
            HStack(spacing: BDDesign.Spacing.md) {
                Text(level.emoji)
                    .font(.system(size: 24))
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(BDDesign.Typography.bodyMedium)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text(level.detail)
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                if selectedExperience == level {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                }
            }
            .padding(BDDesign.Spacing.md)
            .bdCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Page 5: Preferred Times
    
    private var timesPage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("When do you\nwant to breathe?")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BDDesign.Spacing.sm) {
                ForEach(PreferredTime.allCases, id: \.self) { time in
                    timeCard(time)
                }
            }
            .padding(.horizontal, BDDesign.Spacing.sm)
            
            // Daily commitment
            VStack(spacing: BDDesign.Spacing.sm) {
                Text("Daily goal")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                HStack(spacing: BDDesign.Spacing.sm) {
                    ForEach([2, 5, 10, 15], id: \.self) { mins in
                        minuteChip(mins)
                    }
                }
                
                Text("Most users start with 5 minutes")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray400)
            }
            .padding(.top, BDDesign.Spacing.sm)
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func timeCard(_ time: PreferredTime) -> some View {
        let isSelected = selectedTimes.contains(time)
        return Button {
            if isSelected { selectedTimes.remove(time) } else { selectedTimes.insert(time) }
            HapticsManager.shared.selection()
        } label: {
            VStack(spacing: BDDesign.Spacing.sm) {
                Image(systemName: time.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? .white : time.color)
                Text(time.rawValue)
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : (colorScheme == .dark ? .white : BDDesign.Colors.gray900))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BDDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .fill(isSelected ? time.color : time.color.opacity(0.08))
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                        .strokeBorder(time.color, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(BDDesign.Motion.quick, value: isSelected)
    }
    
    private func minuteChip(_ mins: Int) -> some View {
        let isSelected = dailyMinutes == mins
        return Button {
            dailyMinutes = mins
            HapticsManager.shared.selection()
        } label: {
            Text("\(mins) min")
                .font(BDDesign.Typography.button)
                .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.7) : BDDesign.Colors.gray600))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? BDDesign.Colors.accentCalm : (colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50))
                )
                .overlay {
                    if !isSelected {
                        Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                    }
                }
        }
        .animation(BDDesign.Motion.quick, value: isSelected)
    }
    
    // MARK: - Page 6: Apple Health
    
    private var healthPage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            Image("applehealth")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.bottom, BDDesign.Spacing.sm)
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Clinical\nIntegration")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .multilineTextAlignment(.center)
                
                Text("Sync your biomarkers with Apple Health and maintain a comprehensive physiological record.")
                    .font(BDDesign.Typography.bodyLarge)
                    .foregroundStyle(BDDesign.Colors.gray500)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, BDDesign.Spacing.md)
            
            // Health Toggle Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clinical Integration")
                        .font(BDDesign.Typography.bodySemibold)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text("Physiological Metrics")
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                Toggle("", isOn: $healthKitEnabled)
                    .labelsHidden()
                    .tint(Color(hex: 0xFA5655)) // Apple Health Pink
                    .onChange(of: healthKitEnabled) { _, newValue in
                        if newValue {
                            Task {
                                let success = await HealthManager.shared.requestAuthorization()
                                if !success {
                                    healthKitEnabled = false
                                }
                            }
                        }
                    }
            }
            .padding(BDDesign.Spacing.lg)
            .bdCard()
            .padding(.top, BDDesign.Spacing.lg)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    // MARK: - Page 7: Personal Plan
    
    private var personalPlanPage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            if planGenerationState != .ready {
                // Loading State
                BreedyImageView(imageName: "breedy_awake", size: 140, auraColor: BDDesign.Colors.accentFocus)
                    .scaleEffect(planGenerationState == .building ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: planGenerationState)
                
                VStack(spacing: BDDesign.Spacing.xl) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(BDDesign.Colors.accentCalm)
                    
                    Text(planGenerationState.text)
                        .font(BDDesign.Typography.subheadingLarge)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                }
            } else {
                // Ready State
                BreedyImageView(imageName: "breedy_greet", size: 140, auraColor: Color(hex: 0xFFD700))
                
                VStack(spacing: BDDesign.Spacing.md) {
                    let titleText = userName.isEmpty ? "Your plan\nis ready" : "\(userName),\nyour plan is ready"
                    Text(titleText)
                        .font(BDDesign.Typography.displayHero)
                        .tracking(-2.0)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        .multilineTextAlignment(.center)
                    
                    Text(personalizedSummary)
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(BDDesign.Colors.gray500)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            
            // Personalized plan cards
            if planGenerationState == .ready {
                VStack(spacing: BDDesign.Spacing.sm) {
                    planCard(
                        icon: recommendedPattern.icon,
                        title: "Recommended pattern",
                        value: recommendedPattern.title,
                        color: recommendedPattern.accentColor
                    )
                    
                    planCard(
                        icon: "chart.bar.fill",
                        title: "Level",
                        value: selectedExperience?.rawValue ?? "Beginner",
                        color: BDDesign.Colors.accentAnxiety
                    )
                    
                    planCard(
                        icon: "clock.fill",
                        title: "Daily commitment",
                        value: "\(dailyMinutes) minutes per day",
                        color: BDDesign.Colors.accentFocus
                    )
                    
                    planCard(
                        icon: "sparkles",
                        title: "Expected benefit",
                        value: expectedBenefit,
                        color: BDDesign.Colors.accentSleep
                    )
                }
                .padding(.horizontal, BDDesign.Spacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func planCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: BDDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
                Text(value)
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            }
            
            Spacer()
        }
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
    
    // MARK: - Navigation Logic
    
    private var canAdvance: Bool {
        switch currentPage {
        case 0: return true
        case 1: return true  // name is optional
        case 2: return selectedGoal != nil
        case 3: return selectedExperience != nil
        case 4: return !selectedTimes.isEmpty
        case 5: return true
        case 6: return true
        default: return true
        }
    }
    
    private func advance() {
        if currentPage < totalPages - 1 {
            withAnimation(BDDesign.Motion.standard) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
        HapticsManager.shared.tap()
    }
    
    private func completeOnboarding() {
        // Save all personalization data
        appState.userName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.userGoal = selectedGoal?.rawValue ?? ""
        appState.userExperience = selectedExperience?.rawValue ?? "never"
        appState.preferredTimes = selectedTimes.map(\.rawValue).joined(separator: ",")
        appState.dailyGoalMinutes = dailyMinutes
        appState.mascotEnabled = true
        
        // Set up reminders if morning/evening times are selected
        if selectedTimes.contains(.morning) || selectedTimes.contains(.beforeSleep) {
            Task {
                _ = await NotificationManager.shared.requestAuthorization()
                if selectedTimes.contains(.morning) {
                    NotificationManager.shared.morningReminderEnabled = true
                }
                if selectedTimes.contains(.beforeSleep) {
                    NotificationManager.shared.eveningReminderEnabled = true
                }
                NotificationManager.shared.streakReminderEnabled = true
                NotificationManager.shared.scheduleAllReminders()
            }
        }
        
        appState.hasSeenOnboarding = true
    }
    
    // MARK: - Personalization Helpers
    
    private func startGenerationSequence() {
        planGenerationState = .analyzing
        HapticsManager.shared.tap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(BDDesign.Motion.standard) {
                self.planGenerationState = .building
            }
            HapticsManager.shared.tap()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.planGenerationState = .ready
                }
                HapticsManager.shared.milestone()
            }
        }
    }
    
    private var recommendedPattern: BreathingPattern {
        guard let goal = selectedGoal else { return BreathingPresets.coherentBreathing }
        switch goal {
        case .stress:  return BreathingPresets.physiologicalSigh
        case .focus:   return BreathingPresets.boxBreathing
        case .sleep:   return BreathingPresets.fourSevenEight
        case .habit:   return BreathingPresets.coherentBreathing
        case .anxiety: return BreathingPresets.physiologicalSigh
        case .energy:  return BreathingPresets.kapalabhati
        }
    }
    
    private var personalizedSummary: String {
        let goalText = selectedGoal?.rawValue.lowercased() ?? "wellness"
        let expText = selectedExperience?.rawValue.lowercased() ?? "beginner"
        return "We've crafted a routine specifically for a \(expText) looking to \(goalText)."
    }
    
    private var expectedBenefit: String {
        guard let goal = selectedGoal else { return "Noticeable calm after 7 days" }
        switch goal {
        case .stress:  return "Feel calmer within 7 days"
        case .focus:   return "Sharper focus in 5 days"
        case .sleep:   return "Better sleep in 1 week"
        case .habit:   return "Lasting habit in 21 days"
        case .anxiety: return "Reduced anxiety in 3 days"
        case .energy:  return "More energy in 5 days"
        }
    }
}

// MARK: - Onboarding Goal

enum OnboardingGoal: String, CaseIterable {
    case stress = "Reduce Stress"
    case focus = "Improve Focus"
    case sleep = "Better Sleep"
    case habit = "Build a Habit"
    case anxiety = "Manage Anxiety"
    case energy = "Boost Energy"
    
    var icon: String {
        switch self {
        case .stress:  return "heart.fill"
        case .focus:   return "scope"
        case .sleep:   return "moon.fill"
        case .habit:   return "flame.fill"
        case .anxiety: return "shield.fill"
        case .energy:  return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .stress:  return BDDesign.Colors.accentAnxiety
        case .focus:   return BDDesign.Colors.accentFocus
        case .sleep:   return BDDesign.Colors.accentSleep
        case .habit:   return BDDesign.Colors.accentEnergy
        case .anxiety: return BDDesign.Colors.accentAnxiety
        case .energy:  return BDDesign.Colors.accentEnergy
        }
    }
    
    var subtitle: String {
        switch self {
        case .stress:  return "Calm your nervous system"
        case .focus:   return "Sharpen concentration & clarity"
        case .sleep:   return "Fall asleep faster, sleep deeper"
        case .habit:   return "Create a daily mindfulness routine"
        case .anxiety: return "Quick relief when you need it"
        case .energy:  return "Natural energy without caffeine"
        }
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, CaseIterable {
    case never = "Complete Beginner"
    case few = "Tried a Few Times"
    case regular = "Practice Regularly"
    case daily = "Daily Practice"
    
    var emoji: String {
        switch self {
        case .never:   return "🌱"
        case .few:     return "🌿"
        case .regular: return "🌳"
        case .daily:   return "🧘"
        }
    }
    
    var detail: String {
        switch self {
        case .never:   return "Never done breathing exercises"
        case .few:     return "I've explored a bit"
        case .regular: return "A few times per week"
        case .daily:   return "It's part of my routine"
        }
    }
}

// MARK: - Preferred Time

enum PreferredTime: String, CaseIterable {
    case morning = "Morning"
    case workBreak = "Work Break"
    case beforeSleep = "Before Sleep"
    case afterWork = "After Work"
    case workout = "Pre-Workout"
    case anyTime = "Any Time"
    
    var icon: String {
        switch self {
        case .morning:      return "sunrise.fill"
        case .workBreak:    return "briefcase.fill"
        case .beforeSleep:  return "moon.stars.fill"
        case .afterWork:    return "house.fill"
        case .workout:      return "figure.run"
        case .anyTime:      return "clock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morning:      return Color(hex: 0xFF9800)
        case .workBreak:    return BDDesign.Colors.accentFocus
        case .beforeSleep:  return BDDesign.Colors.accentSleep
        case .afterWork:    return BDDesign.Colors.accentAnxiety
        case .workout:      return BDDesign.Colors.accentEnergy
        case .anyTime:      return BDDesign.Colors.accentCalm
        }
    }
}

// MARK: - Plan Generation State

enum PlanGenerationState {
    case idle
    case analyzing
    case building
    case ready
    
    var text: String {
        switch self {
        case .idle: return ""
        case .analyzing: return "Analyzing profile..."
        case .building: return "Tailoring sessions..."
        case .ready: return "Your plan is ready"
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
