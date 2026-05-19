import SwiftUI
import Charts

// MARK: - Insights View (Wellness Dashboard)

struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var stats: UserStats?
    @State private var recentCheckIns: [DailyCheckIn] = []
    @State private var showCheckIn = false
    @State private var hasCheckedInToday = false
    
    // Check-in state
    @State private var stressLevel: Int = 3
    @State private var moodLevel: Int = 3
    @State private var energyLevel: Int = 3
    @State private var sleepQuality: Int = 3
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Breedy + Wellness Score
                    wellnessHero
                    
                    // Daily check-in
                    if !hasCheckedInToday {
                        checkInPrompt
                    }
                    
                    if showCheckIn {
                        checkInForm
                    }
                    
                    // Weekly trends
                    if !recentCheckIns.isEmpty {
                        weeklyTrendsSection
                    }
                    
                    // Science tip
                    scienceTipCard
                    
                    // Body benefits timeline
                    bodyBenefitsTimeline
                    
                    // Breathing impact
                    breathingImpactSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { refreshData() }
    }
    
    // MARK: - Wellness Hero
    
    private var wellnessHero: some View {
        HStack(spacing: BDDesign.Spacing.lg) {
            // Breedy mascot
            BreedyImageView(
                imageName: heroImageName,
                size: 90,
                auraColor: BDDesign.Colors.accentCalm
            )
            
            // Wellness score
            VStack(alignment: .leading, spacing: 6) {
                Text("Wellness Score")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.gray500)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(wellnessScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    Text("/ 100")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray400)
                }
                
                // Score bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : BDDesign.Colors.gray100)
                        Capsule()
                            .fill(wellnessGradient)
                            .frame(width: max(geo.size.width * CGFloat(wellnessScore) / 100.0, 4))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
                
                Text(wellnessLabel)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(wellnessColor)
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
        .padding(.top, BDDesign.Spacing.sm)
    }
    
    // MARK: - Check-in Prompt
    
    private var checkInPrompt: some View {
        Button {
            withAnimation(BDDesign.Motion.standard) { showCheckIn = true }
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
                    Text("Track your mood, stress, and energy")
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
            HStack {
                Text("How are you right now?")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                Spacer()
                Button { withAnimation(BDDesign.Motion.standard) { showCheckIn = false } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BDDesign.Colors.gray400)
                        .padding(8)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50))
                }
            }
            
            checkInRow("Stress", value: $stressLevel, low: "Low", high: "High", color: BDDesign.Colors.accentAnxiety, icon: "brain.head.profile")
            checkInRow("Mood", value: $moodLevel, low: "Low", high: "Great", color: BDDesign.Colors.accentCalm, icon: "face.smiling")
            checkInRow("Energy", value: $energyLevel, low: "Tired", high: "Energized", color: BDDesign.Colors.accentEnergy, icon: "bolt.fill")
            checkInRow("Sleep", value: $sleepQuality, low: "Poor", high: "Excellent", color: BDDesign.Colors.accentSleep, icon: "moon.fill")
            
            Button { saveCheckIn() } label: {
                Text("Save Check-in")
                    .bdPrimaryButton()
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func checkInRow(_ title: String, value: Binding<Int>, low: String, high: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
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
                            .fill(level <= value.wrappedValue ? color : color.opacity(0.12))
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
                Text(low).font(BDDesign.Typography.caption).foregroundStyle(BDDesign.Colors.gray400)
                Spacer()
                Text(high).font(BDDesign.Typography.caption).foregroundStyle(BDDesign.Colors.gray400)
            }
        }
    }
    
    // MARK: - Weekly Trends
    
    private var weeklyTrendsSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BDDesign.Colors.accentFocus)
                Text("Weekly Trends")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BDDesign.Spacing.sm) {
                trendCard("Stress", data: recentCheckIns.map(\.stressLevel), color: BDDesign.Colors.accentAnxiety, icon: "brain.head.profile", inverted: true)
                trendCard("Mood", data: recentCheckIns.map(\.moodLevel), color: BDDesign.Colors.accentCalm, icon: "face.smiling", inverted: false)
                trendCard("Energy", data: recentCheckIns.map(\.energyLevel), color: BDDesign.Colors.accentEnergy, icon: "bolt.fill", inverted: false)
                trendCard("Sleep", data: recentCheckIns.map(\.sleepQuality), color: BDDesign.Colors.accentSleep, icon: "moon.fill", inverted: false)
            }
        }
    }
    
    private func trendCard(_ title: String, data: [Int], color: Color, icon: String, inverted: Bool) -> some View {
        let avg = data.isEmpty ? 0.0 : Double(data.reduce(0, +)) / Double(data.count)
        let trend = data.count >= 2 ? Double(data.last! - data.first!) : 0
        let trendText: String
        if inverted {
            if trend < 0 { trendText = "↓ Improving" }
            else if trend > 0 { trendText = "↑ Rising" }
            else { trendText = "→ Stable" }
        } else {
            if trend > 0 { trendText = "↑ Improving" }
            else if trend < 0 { trendText = "↓ Declining" }
            else { trendText = "→ Stable" }
        }
        let isGood = inverted ? trend <= 0 : trend >= 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)
                Text(title)
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            Text(String(format: "%.1f", avg))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            // Mini sparkline
            if data.count >= 2 {
                Chart(Array(data.enumerated()), id: \.offset) { i, val in
                    LineMark(
                        x: .value("Day", i),
                        y: .value("Val", val)
                    )
                    .foregroundStyle(color.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", i),
                        y: .value("Val", val)
                    )
                    .foregroundStyle(color.opacity(0.08))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 1...5)
                .frame(height: 32)
            }
            
            Text(trendText)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(isGood ? Color(hex: 0x4CAF50) : BDDesign.Colors.accentAnxiety)
        }
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
    
    // MARK: - Science Tip
    
    private var scienceTipCard: some View {
        let tip = scienceTips[Calendar.current.component(.day, from: Date()) % scienceTips.count]
        
        return VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BDDesign.Colors.accentFocus)
                Text("Science of Breathing")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.gray500)
                Spacer()
                Text("Daily Insight")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.accentFocus)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(BDDesign.Colors.accentFocus.opacity(0.1), in: Capsule())
            }
            
            Text(tip.title)
                .font(BDDesign.Typography.bodySemibold)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            Text(tip.body)
                .font(BDDesign.Typography.bodySmall)
                .foregroundStyle(BDDesign.Colors.gray600)
                .lineSpacing(3)
            
            if !tip.source.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 9))
                    Text(tip.source)
                        .font(BDDesign.Typography.caption)
                }
                .foregroundStyle(BDDesign.Colors.gray400)
                .padding(.top, 2)
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Body Benefits Timeline
    
    private var bodyBenefitsTimeline: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BDDesign.Colors.accentCalm)
                Text("Your Body on Breathwork")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            }
            
            let totalMin = stats?.totalMinutes ?? 0
            
            ForEach(Array(benefitMilestones.enumerated()), id: \.offset) { index, milestone in
                let isReached = totalMin >= milestone.minutesNeeded
                
                HStack(alignment: .top, spacing: BDDesign.Spacing.md) {
                    // Timeline dot + line
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isReached ? milestone.color : BDDesign.Colors.gray400)
                            .frame(width: 12, height: 12)
                            .overlay {
                                if isReached {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 4, height: 4)
                                }
                            }
                        
                        if index < benefitMilestones.count - 1 {
                            Rectangle()
                                .fill(isReached ? milestone.color.opacity(0.3) : BDDesign.Colors.gray100)
                                .frame(width: 2, height: 36)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(milestone.title)
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(isReached ? (colorScheme == .dark ? .white : BDDesign.Colors.gray900) : BDDesign.Colors.gray400)
                        
                        Text(milestone.detail)
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(isReached ? BDDesign.Colors.gray500 : BDDesign.Colors.gray400)
                        
                        if isReached {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Achieved")
                                    .font(BDDesign.Typography.caption)
                            }
                            .foregroundStyle(Color(hex: 0x4CAF50))
                        }
                    }
                    .padding(.top, -3)
                }
                .opacity(isReached ? 1 : 0.6)
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Breathing Impact
    
    private var breathingImpactSection: some View {
        let totalMin = stats?.totalMinutes ?? 0
        let sessions = stats?.totalSessions ?? 0
        
        return VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "lungs.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BDDesign.Colors.accentCalm)
                Text("Your Impact")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BDDesign.Spacing.sm) {
                impactTile(
                    value: "\(totalMin)",
                    unit: "minutes",
                    subtitle: "of mindful breathing",
                    icon: "clock.fill",
                    color: BDDesign.Colors.accentCalm
                )
                impactTile(
                    value: "\(sessions)",
                    unit: "sessions",
                    subtitle: "completed",
                    icon: "wind",
                    color: BDDesign.Colors.accentFocus
                )
                impactTile(
                    value: "~\(max(totalMin * 2, 1))",
                    unit: "breaths",
                    subtitle: "of focused breathing",
                    icon: "lungs.fill",
                    color: BDDesign.Colors.accentEnergy
                )
                impactTile(
                    value: "~\(max(sessions * 15, 1))%",
                    unit: "",
                    subtitle: "est. cortisol reduction",
                    icon: "arrow.down.heart.fill",
                    color: BDDesign.Colors.accentAnxiety
                )
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    private func impactTile(value: String, unit: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                if !unit.isEmpty {
                    Text(unit)
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            
            Text(subtitle)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray400)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BDDesign.Spacing.md)
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        stats = statsManager.computeStats()
        recentCheckIns = statsManager.recentCheckIns(days: 7)
        hasCheckedInToday = statsManager.todayCheckIn() != nil
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
            hasCheckedInToday = true
            showCheckIn = false
        }
        refreshData()
        HapticsManager.shared.milestone()
    }
    
    private var heroImageName: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 { return "breedy_sleep" }
        return "breedy_awake"
    }
    
    private var wellnessScore: Int {
        var score = 30 // base
        let streak = stats?.currentStreak ?? 0
        let todayMin = stats?.todayMinutes ?? 0
        let goalMin = Double(appState.dailyGoalMinutes)
        
        // Streak contribution (up to 25 pts)
        score += min(streak * 5, 25)
        
        // Today's goal progress (up to 25 pts)
        if goalMin > 0 { score += min(Int((todayMin / goalMin) * 25.0), 25) }
        
        // Check-in mood (up to 20 pts)
        if let latest = recentCheckIns.first {
            let mood = latest.moodLevel
            let stress = 6 - latest.stressLevel // invert
            score += (mood + stress) * 2
        }
        
        return min(score, 100)
    }
    
    private var wellnessLabel: String {
        switch wellnessScore {
        case 0..<30:  return "Getting started"
        case 30..<50: return "Building momentum"
        case 50..<70: return "On track"
        case 70..<85: return "Thriving"
        default:      return "Peak wellness"
        }
    }
    
    private var wellnessColor: Color {
        switch wellnessScore {
        case 0..<30:  return BDDesign.Colors.gray500
        case 30..<50: return BDDesign.Colors.accentEnergy
        case 50..<70: return BDDesign.Colors.accentCalm
        case 70..<85: return Color(hex: 0x4CAF50)
        default:      return Color(hex: 0xFFD700)
        }
    }
    
    private var wellnessGradient: LinearGradient {
        LinearGradient(
            colors: [BDDesign.Colors.accentCalm, wellnessColor],
            startPoint: .leading, endPoint: .trailing
        )
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
}

// MARK: - Science Tips

private struct ScienceTip {
    let title: String
    let body: String
    let source: String
}

private let scienceTips: [ScienceTip] = [
    ScienceTip(
        title: "Your vagus nerve is a superpower",
        body: "The vagus nerve connects your brain to your gut, heart, and lungs. Slow exhales directly stimulate it, activating your body's natural calming system.",
        source: "Porges, 2011 — Polyvagal Theory"
    ),
    ScienceTip(
        title: "5.5 breaths per minute is the magic number",
        body: "Research shows breathing at ~5.5 breaths/minute maximizes Heart Rate Variability (HRV) — the gold-standard biomarker for stress resilience and longevity.",
        source: "Lehrer et al., 2003"
    ),
    ScienceTip(
        title: "Breathing changes your brain waves",
        body: "Slow, rhythmic breathing increases alpha brain wave activity — the same pattern seen during meditation. This promotes a state of calm alertness.",
        source: "Zaccaro et al., 2018"
    ),
    ScienceTip(
        title: "Exhale longer to calm instantly",
        body: "When your exhale is longer than your inhale, your heart rate naturally decreases through respiratory sinus arrhythmia — a direct vagal brake mechanism.",
        source: "Gerritsen & Band, 2018"
    ),
    ScienceTip(
        title: "3 minutes can reduce cortisol by 15%",
        body: "A Stanford study found that just 5 minutes of structured breathwork reduced cortisol and improved mood more effectively than meditation alone.",
        source: "Balban et al., 2023 — Cell Reports Medicine"
    ),
    ScienceTip(
        title: "HRV predicts your stress resilience",
        body: "Higher HRV means your nervous system can quickly adapt between calm and alert states. Regular breathwork is one of the most effective ways to improve HRV.",
        source: "Shaffer & Ginsberg, 2017"
    ),
    ScienceTip(
        title: "Your breath shapes your immune response",
        body: "Controlled breathing has been shown to modulate inflammatory markers. Slow breathing reduces pro-inflammatory cytokines and supports immune function.",
        source: "Kox et al., 2014 — PNAS"
    ),
]

// MARK: - Benefit Milestones

private struct BenefitMilestone {
    let title: String
    let detail: String
    let minutesNeeded: Int
    let color: Color
}

private let benefitMilestones: [BenefitMilestone] = [
    BenefitMilestone(title: "First Session", detail: "Cortisol drops ~15%. Parasympathetic activation begins.", minutesNeeded: 1, color: BDDesign.Colors.accentCalm),
    BenefitMilestone(title: "30 Minutes Total", detail: "Improved vagal tone. Your body remembers the calm.", minutesNeeded: 30, color: BDDesign.Colors.accentFocus),
    BenefitMilestone(title: "1 Week Consistent", detail: "HRV begins to improve. Better sleep onset latency.", minutesNeeded: 35, color: BDDesign.Colors.accentSleep),
    BenefitMilestone(title: "100 Minutes Total", detail: "Measurable anxiety reduction. Emotional regulation improves.", minutesNeeded: 100, color: BDDesign.Colors.accentAnxiety),
    BenefitMilestone(title: "500 Minutes Total", detail: "Long-term nervous system remodeling. Baseline stress decreases.", minutesNeeded: 500, color: BDDesign.Colors.accentEnergy),
    BenefitMilestone(title: "1000 Minutes Total", detail: "Mastery. Your resting HRV reflects a calmer, more resilient you.", minutesNeeded: 1000, color: Color(hex: 0xFFD700)),
]

#Preview {
    InsightsView()
        .environment(AppState())
        .environment(StatsManager())
}
