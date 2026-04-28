import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var currentPage = 0
    @State private var selectedGoal: OnboardingGoal?
    @State private var reminderEnabled = true
    @State private var mascotEnabled = true
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color(hex: 0x0A0A0A) : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= currentPage ? BDDesign.Colors.gray900 : BDDesign.Colors.gray100)
                            .frame(width: index == currentPage ? 24 : 8, height: 6)
                            .animation(BDDesign.Motion.standard, value: currentPage)
                    }
                }
                .padding(.top, BDDesign.Spacing.xl)
                
                // Pages
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    goalPage.tag(1)
                    preferencesPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(BDDesign.Motion.standard, value: currentPage)
                
                // Continue button
                Button {
                    advance()
                } label: {
                    Text(currentPage == 2 ? "Let's Breathe" : "Continue")
                        .font(BDDesign.Typography.bodyMedium)
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
            
            BreedyMascotView(mood: .happy, size: 140)
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Meet Breedy")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Text("Your gentle breathing companion.\nCalm, focused, rested — in seconds.")
                    .font(BDDesign.Typography.bodyLarge)
                    .foregroundStyle(BDDesign.Colors.gray600)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Value badges
            HStack(spacing: BDDesign.Spacing.sm) {
                valueBadge("No accounts", icon: "person.slash.fill")
                valueBadge("100% private", icon: "lock.fill")
                valueBadge("Works offline", icon: "wifi.slash")
            }
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    private func valueBadge(_ text: String, icon: String) -> some View {
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
    
    // MARK: - Page 2: Goal
    
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
                
                Text(goal.rawValue)
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
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
    
    // MARK: - Page 3: Preferences
    
    private var preferencesPage: some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            BreedyMascotView(mood: .celebrating, size: 100)
            
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Almost ready!")
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-2.0)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Text("Just a couple of preferences")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            VStack(spacing: BDDesign.Spacing.md) {
                // Reminder toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminders")
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        Text("Gentle nudges to keep your streak")
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .tint(BDDesign.Colors.accentCalm)
                        .labelsHidden()
                }
                .padding(BDDesign.Spacing.md)
                .bdCard()
                
                // Mascot toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Breedy Companion")
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        Text("Show Breedy throughout the app")
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    Spacer()
                    Toggle("", isOn: $mascotEnabled)
                        .tint(BDDesign.Colors.accentCalm)
                        .labelsHidden()
                }
                .padding(BDDesign.Spacing.md)
                .bdCard()
            }
            .padding(.horizontal, BDDesign.Spacing.sm)
            
            Spacer()
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
    }
    
    // MARK: - Actions
    
    private var canAdvance: Bool {
        switch currentPage {
        case 0: return true
        case 1: return selectedGoal != nil
        case 2: return true
        default: return true
        }
    }
    
    private func advance() {
        if currentPage < 2 {
            withAnimation(BDDesign.Motion.standard) {
                currentPage += 1
            }
        } else {
            // Complete onboarding
            appState.userGoal = selectedGoal?.rawValue ?? ""
            appState.mascotEnabled = mascotEnabled
            
            if reminderEnabled {
                Task {
                    _ = await NotificationManager.shared.requestAuthorization()
                    NotificationManager.shared.morningReminderEnabled = true
                    NotificationManager.shared.streakReminderEnabled = true
                    NotificationManager.shared.scheduleAllReminders()
                }
            }
            
            appState.hasSeenOnboarding = true
        }
        HapticsManager.shared.tap()
    }
}

// MARK: - Onboarding Goal

enum OnboardingGoal: String, CaseIterable {
    case stress = "Reduce Stress"
    case focus = "Improve Focus"
    case sleep = "Better Sleep"
    case habit = "Build a Habit"
    
    var icon: String {
        switch self {
        case .stress: return "heart.fill"
        case .focus:  return "scope"
        case .sleep:  return "moon.fill"
        case .habit:  return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .stress: return BDDesign.Colors.accentAnxiety
        case .focus:  return BDDesign.Colors.accentFocus
        case .sleep:  return BDDesign.Colors.accentSleep
        case .habit:  return BDDesign.Colors.accentEnergy
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
