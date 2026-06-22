import Foundation

// MARK: - Widget Data Provider
// Shared between main app (write) and widget extension (read)
// Uses App Group UserDefaults for cross-process data sharing.

struct WidgetData: Codable {
    let currentStreak: Int
    let todayMinutes: Double
    let todaySessions: Int
    let totalMinutes: Int
    let totalSessions: Int
    let level: Int
    let totalXP: Int
    let weeklyConsistency: Double
    let lastSessionPattern: String?
    let lastSessionDate: Date?
    let last7DaysMinutes: [Double]  // index 0 = 6 days ago, index 6 = today
    let updatedAt: Date
    
    static let empty = WidgetData(
        currentStreak: 0,
        todayMinutes: 0,
        todaySessions: 0,
        totalMinutes: 0,
        totalSessions: 0,
        level: 1,
        totalXP: 0,
        weeklyConsistency: 0,
        lastSessionPattern: nil,
        lastSessionDate: nil,
        last7DaysMinutes: Array(repeating: 0, count: 7),
        updatedAt: Date()
    )
}

enum WidgetDataProvider {
    static let suiteName = "group.com.lvrpiz.breedy"
    static let dataKey = "widgetData"
    
    /// Write widget data from the main app
    static func write(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: dataKey)
        }
    }
    
    /// Read widget data from the widget extension
    static func read() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return decoded
    }
}
