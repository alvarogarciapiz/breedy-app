import SwiftUI
import Charts

// MARK: - Progress View

struct ProgressView_: View {
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var stats: UserStats?
    @State private var weeklyData: [(Date, Double)] = []
    @State private var monthlyData: [(Date, Double)] = []
    @State private var unlockedBadges: Set<String> = []
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case year = "1Y"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Level & XP
                    levelSection
                    
                    // Stats grid
                    statsGrid
                    
                    // Chart
                    chartSection
                    
                    // Heatmap (Year view)
                    if selectedTimeRange == .year {
                        heatmapSection
                    }
                    
                    // Badges
                    badgesSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { refreshData() }
    }
    
    // MARK: - Level Section
    
    private var levelSection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(stats?.level ?? 1)")
                        .font(BDDesign.Typography.sectionHeading)
                        .tracking(-1.28)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text("\(stats?.totalXP ?? 0) XP total")
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                
                Spacer()
                
                BreedyMascotView(
                    mood: levelMascotMood,
                    size: 56
                )
            }
            
            // XP Progress bar
            let xpInfo = statsManager.xpForNextLevel(currentXP: stats?.totalXP ?? 0)
            VStack(spacing: 4) {
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
                .frame(height: 6)
                .clipShape(Capsule())
                
                HStack {
                    Text("\(xpInfo.current) / \(xpInfo.needed) XP")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                    Spacer()
                    Text("Next level")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray400)
                }
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BDDesign.Spacing.sm) {
            StatTileView(
                title: "Total Minutes",
                value: "\(stats?.totalMinutes ?? 0)",
                icon: "clock.fill",
                accentColor: BDDesign.Colors.accentCalm
            )
            StatTileView(
                title: "Sessions",
                value: "\(stats?.totalSessions ?? 0)",
                icon: "wind",
                accentColor: BDDesign.Colors.accentFocus
            )
            StatTileView(
                title: "Current Streak",
                value: "\(stats?.currentStreak ?? 0)d",
                icon: "flame.fill",
                accentColor: BDDesign.Colors.accentEnergy
            )
            StatTileView(
                title: "Longest Streak",
                value: "\(stats?.longestStreak ?? 0)d",
                icon: "crown.fill",
                accentColor: BDDesign.Colors.accentSleep
            )
        }
    }
    
    // MARK: - Chart
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Breathing History")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                // Time range picker
                HStack(spacing: 4) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button {
                            withAnimation(BDDesign.Motion.quick) {
                                selectedTimeRange = range
                                refreshChartData()
                            }
                        } label: {
                            Text(range.rawValue)
                                .font(BDDesign.Typography.captionMedium)
                                .foregroundStyle(selectedTimeRange == range ? .white : BDDesign.Colors.gray500)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background {
                                    if selectedTimeRange == range {
                                        Capsule().fill(BDDesign.Colors.gray900)
                                    }
                                }
                        }
                    }
                }
                .padding(3)
                .background {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50)
                }
            }
            
            // Chart
            let chartData = selectedTimeRange == .week ? weeklyData : monthlyData
            
            if chartData.isEmpty {
                VStack(spacing: BDDesign.Spacing.sm) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(BDDesign.Colors.gray400)
                    Text("Start breathing to see your progress")
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(chartData, id: \.0) { item in
                    BarMark(
                        x: .value("Date", item.0, unit: .day),
                        y: .value("Minutes", item.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BDDesign.Colors.accentCalm, BDDesign.Colors.accentCalm.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(3)
                }
                .chartYAxisLabel("min")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(BDDesign.Colors.gray100)
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(BDDesign.Colors.gray100)
                        AxisValueLabel()
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Heatmap
    
    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Year in Breath")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            HeatmapView(data: statsManager.yearlyHeatmap())
        }
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Badges
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Achievements")
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
    
    // MARK: - Helpers
    
    private func refreshData() {
        stats = statsManager.computeStats()
        unlockedBadges = statsManager.fetchUnlockedBadgeIds()
        refreshChartData()
    }
    
    private func refreshChartData() {
        switch selectedTimeRange {
        case .week:
            weeklyData = statsManager.minutesPerDay(last: 7)
        case .month:
            monthlyData = statsManager.minutesPerDay(last: 30)
        case .year:
            weeklyData = statsManager.minutesPerDay(last: 7)
        }
    }
    
    private var levelMascotMood: MascotMood {
        let level = stats?.level ?? 1
        switch level {
        case 1...2: return .calm
        case 3...5: return .happy
        case 6...8: return .celebrating
        default:    return .celebrating
        }
    }
}

// MARK: - Badge Card

struct BadgeCardView: View {
    let badge: BadgeDefinition
    let isUnlocked: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            Image(systemName: badge.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isUnlocked ? BDDesign.Colors.accentCalm : BDDesign.Colors.gray400)
                .opacity(isUnlocked ? 1 : 0.4)
            
            Text(badge.title)
                .font(BDDesign.Typography.captionMedium)
                .foregroundStyle(isUnlocked ? (colorScheme == .dark ? .white : BDDesign.Colors.gray900) : BDDesign.Colors.gray400)
                .multilineTextAlignment(.center)
            
            Text(isUnlocked ? "+\(badge.xpReward) XP" : badge.requirement)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(isUnlocked ? BDDesign.Colors.accentCalm : BDDesign.Colors.gray400)
        }
        .frame(maxWidth: .infinity)
        .padding(BDDesign.Spacing.md)
        .bdCard()
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

// MARK: - Heatmap View

struct HeatmapView: View {
    let data: [Date: Double]
    
    private let columns = 52
    private let rows = 7
    private let cellSize: CGFloat = 10
    private let spacing: CGFloat = 2
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: rows), spacing: spacing) {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let totalDays = columns * rows
                
                ForEach(0..<totalDays, id: \.self) { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -(totalDays - 1 - dayOffset), to: today)!
                    let day = calendar.startOfDay(for: date)
                    let minutes = data[day] ?? 0
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(minutes: minutes))
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }
    
    private func heatmapColor(minutes: Double) -> Color {
        if minutes == 0 {
            return BDDesign.Colors.gray100
        } else if minutes < 3 {
            return BDDesign.Colors.accentCalm.opacity(0.3)
        } else if minutes < 10 {
            return BDDesign.Colors.accentCalm.opacity(0.6)
        } else {
            return BDDesign.Colors.accentCalm
        }
    }
}

#Preview {
    ProgressView_()
        .environment(StatsManager())
}
