import SwiftUI
import Charts

// MARK: - Progress View

struct ProgressView_: View {
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var stats: UserStats?
    @State private var weeklyData: [(Date, Double)] = []
    @State private var monthlyData: [(Date, Double)] = []
    @State private var recentSessions: [SessionRecord] = []
    @State private var patternDistribution: [(String, Double)] = []
    @State private var timeOfDayPref: String = ""
    @State private var recentMoods: [DailyCheckIn] = []
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
                    // Insights
                    insightsHeader
                    
                    // Stats grid
                    statsGrid
                    
                    // Time of Day
                    if !timeOfDayPref.isEmpty {
                        timeOfDaySection
                    }
                    
                    // Chart & Heatmap
                    activitySection
                    
                    // Pattern Distribution
                    if !patternDistribution.isEmpty {
                        distributionSection
                    }
                    
                    // Biometric Trends
                    if !recentMoods.isEmpty {
                        biometricTrendsSection
                    }
                    
                    // Recent Sessions
                    recentSessionsSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Clinical Biometrics")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { refreshData() }
    }
    
    // MARK: - Insights Header
    
    private var insightsHeader: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            Text(greetingTitle)
                .font(BDDesign.Typography.sectionHeading)
                .tracking(-1.28)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            Text(insightMessage)
                .font(BDDesign.Typography.body)
                .foregroundStyle(BDDesign.Colors.gray500)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 18 { return "Good Afternoon" }
        return "Good Evening"
    }
    
    private var insightMessage: String {
        let streak = stats?.currentStreak ?? 0
        let minutes = stats?.totalMinutes ?? 0
        
        if streak >= 3 {
            return "You're on a \(streak)-day streak! Consistency is your superpower."
        } else if minutes > 60 {
            return "You've breathed for \(minutes) minutes total. That's a lot of calm."
        } else if minutes > 0 {
            return "Every breath counts. You're doing great."
        } else {
            return "Ready for your first session today?"
        }
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
            let cons = stats?.weeklyConsistency ?? 0.0
            StatTileView(
                title: "Consistency",
                value: "\(Int(cons * 100))%",
                icon: "chart.pie.fill",
                accentColor: BDDesign.Colors.accentSleep
            )
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text(selectedTimeRange == .year ? "Year in Breath" : "Adherence Record")
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
            
            if selectedTimeRange == .year {
                HeatmapView(data: statsManager.yearlyHeatmap())
                    .padding(.top, BDDesign.Spacing.sm)
            } else {
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
                        if selectedTimeRange == .month {
                            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(BDDesign.Colors.gray100)
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    .font(BDDesign.Typography.caption)
                                    .foregroundStyle(BDDesign.Colors.gray500)
                            }
                        } else {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(BDDesign.Colors.gray100)
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    .font(BDDesign.Typography.caption)
                                    .foregroundStyle(BDDesign.Colors.gray500)
                            }
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Clinical Record")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            if recentSessions.isEmpty {
                Text("No recent sessions. Take a deep breath to start!")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, BDDesign.Spacing.xl)
            } else {
                VStack(spacing: BDDesign.Spacing.sm) {
                    ForEach(recentSessions) { session in
                        HStack(spacing: BDDesign.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(BDDesign.Colors.accentCalm.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "wind")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(BDDesign.Colors.accentCalm)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.patternTitle)
                                    .font(BDDesign.Typography.bodySemibold)
                                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                                
                                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(BDDesign.Typography.caption)
                                    .foregroundStyle(BDDesign.Colors.gray500)
                            }
                            
                            Spacer()
                            
                            Text("\(session.durationSeconds / 60) min")
                                .font(BDDesign.Typography.captionMedium)
                                .foregroundStyle(BDDesign.Colors.gray500)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray100))
                        }
                        .padding(BDDesign.Spacing.md)
                        .bdCard()
                    }
                }
            }
        }
    }
    
    // MARK: - Time of Day Section
    
    private var timeOfDaySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rhythm")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Text(timeOfDayPref)
                    .font(BDDesign.Typography.body)
                    .foregroundStyle(BDDesign.Colors.accentEnergy)
            }
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(BDDesign.Colors.gray400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    // MARK: - Pattern Distribution
    
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Protocol Distribution")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            HStack(spacing: BDDesign.Spacing.xl) {
                Chart(patternDistribution, id: \.0) { item in
                    SectorMark(
                        angle: .value("Minutes", item.1),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Pattern", item.0))
                }
                .chartLegend(.hidden)
                .frame(width: 120, height: 120)
                
                VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                    ForEach(Array(patternDistribution.prefix(3).enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForPatternIndex(index))
                                .frame(width: 8, height: 8)
                            Text(item.0)
                                .font(BDDesign.Typography.captionMedium)
                                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.vertical, BDDesign.Spacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    private func colorForPatternIndex(_ index: Int) -> Color {
        let colors = [BDDesign.Colors.accentCalm, BDDesign.Colors.accentFocus, BDDesign.Colors.accentEnergy, BDDesign.Colors.accentSleep]
        return colors[index % colors.count]
    }
    
    // MARK: - Biometric Trends
    
    private var biometricTrendsSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.lg) {
            Text("Readiness Trend (7 Days)")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            // Readiness Line Chart
            Chart(recentMoods) { checkin in
                LineMark(
                    x: .value("Date", checkin.date, unit: .day),
                    y: .value("Readiness", checkin.readinessScore)
                )
                .foregroundStyle(BDDesign.Colors.accentFocus)
                .symbol(BasicChartSymbolShape.circle)
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Date", checkin.date, unit: .day),
                    y: .value("Readiness", checkin.readinessScore)
                )
                .foregroundStyle(LinearGradient(colors: [BDDesign.Colors.accentFocus.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            }
            .chartYScale(domain: 0...100)
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
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(BDDesign.Colors.gray100)
                    AxisValueLabel()
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            .frame(height: 160)
            
            Divider().background(BDDesign.Colors.gray100).padding(.vertical, BDDesign.Spacing.sm)
            
            // Latest Biometric Breakdown
            if let latest = recentMoods.last {
                Text("Latest Biomarkers")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                VStack(spacing: BDDesign.Spacing.md) {
                    biometricBar(title: "Sleep Architecture", value: latest.sleepQuality, color: BDDesign.Colors.accentSleep)
                    biometricBar(title: "Metabolic Energy", value: latest.energyLevel, color: BDDesign.Colors.accentEnergy)
                    biometricBar(title: "Valence / Mood", value: latest.moodLevel, color: BDDesign.Colors.accentCalm)
                    biometricBar(title: "Cortisol (Inverted)", value: 6 - latest.stressLevel, color: BDDesign.Colors.accentAnxiety)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BDDesign.Spacing.lg)
        .bdCard()
    }
    
    private func biometricBar(title: String, value: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(BDDesign.Typography.captionMedium)
                .foregroundStyle(BDDesign.Colors.gray600)
                .frame(width: 130, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray100)
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, geo.size.width * CGFloat(value) / 5.0), height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(value)/5")
                .font(BDDesign.Typography.monoCaption)
                .foregroundStyle(BDDesign.Colors.gray500)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    // MARK: - Helpers
    
    private func refreshData() {
        stats = statsManager.computeStats()
        recentSessions = Array(statsManager.fetchAllSessions().prefix(5))
        patternDistribution = statsManager.patternDistribution()
        timeOfDayPref = statsManager.timeOfDayPreference()
        recentMoods = statsManager.recentCheckIns(days: 7)
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
