import WidgetKit
import SwiftUI
import Charts

// MARK: - Provider

struct BreedyHomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BreedyHomeWidgetEntry {
        BreedyHomeWidgetEntry(date: Date(), data: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (BreedyHomeWidgetEntry) -> Void) {
        let entry = BreedyHomeWidgetEntry(date: Date(), data: WidgetDataProvider.read())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreedyHomeWidgetEntry>) -> Void) {
        // Read the latest data from the App Group
        let data = WidgetDataProvider.read()
        let entry = BreedyHomeWidgetEntry(date: Date(), data: data)
        
        // Widget only needs to refresh when the user completes a session,
        // which triggers WidgetCenter.shared.reloadAllTimelines() from the main app.
        // We set policy to .never because the app explicitly pushes updates.
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry

struct BreedyHomeWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Widget View

struct BreedyHomeWidgetEntryView : View {
    var entry: BreedyHomeWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 16, weight: .bold))
                Text("Streak")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Streak
            Text("\(data.currentStreak)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            
            Text(data.currentStreak == 1 ? "day" : "days")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            // Today
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                Text("Today: \(Int(data.todayMinutes)) min")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.white.opacity(0.1), in: Capsule())
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Streak
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Streak")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Text("\(data.currentStreak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Days in a row")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(Int(data.todayMinutes)) min today")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.15), in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right: Chart
            VStack(alignment: .leading, spacing: 4) {
                Text("LAST 7 DAYS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                
                Chart {
                    ForEach(Array(data.last7DaysMinutes.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Minutes", value)
                        )
                        .foregroundStyle(index == 6 ? .white : .white.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...max(10, (data.last7DaysMinutes.max() ?? 0) * 1.2))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Row
            HStack(spacing: 16) {
                // Streak Card
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 14))
                    Text("\(data.currentStreak)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Day Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                
                // XP Card
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 14))
                    Text("\(data.totalXP)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Total XP")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Chart Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LAST 7 DAYS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("\(Int(data.todayMinutes)) min today")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Chart {
                    ForEach(Array(data.last7DaysMinutes.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Minutes", value)
                        )
                        .foregroundStyle(index == 6 ? .white : .white.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...max(10, (data.last7DaysMinutes.max() ?? 0) * 1.2))
            }
            .padding(12)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            
            // Last Session Footer
            if let pattern = data.lastSessionPattern {
                HStack {
                    Image(systemName: "wind")
                    Text("Last: \(pattern)")
                        .lineLimit(1)
                    Spacer()
                    if let date = data.lastSessionDate {
                        Text(date, format: .relative(presentation: .numeric))
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Widget Configuration

struct BreedyHomeWidget: Widget {
    let kind: String = "BreedyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreedyHomeWidgetProvider()) { entry in
            BreedyHomeWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.05), for: .widget)
        }
        .configurationDisplayName("Breathing Stats")
        .description("Track your streak and daily minutes directly from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
