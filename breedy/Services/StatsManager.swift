import SwiftUI
import SwiftData
import Observation
import WidgetKit

// MARK: - Stats Manager

@Observable
@MainActor
final class StatsManager {
    
    private var modelContext: ModelContext?
    
    var showLevelUp: Bool = false
    var newLevelReached: Int? = nil
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Session Recording
    
    func recordSession(
        pattern: BreathingPattern,
        durationSeconds: Int,
        completedCycles: Int,
        wasCompleted: Bool,
        moodBefore: String? = nil,
        moodAfter: String? = nil,
        stressBefore: Int? = nil,
        stressAfter: Int? = nil
    ) -> SessionRecord? {
        guard let context = modelContext else { return nil }
        
        let xp = calculateXP(durationSeconds: durationSeconds, wasCompleted: wasCompleted)
        
        let record = SessionRecord(
            patternTitle: pattern.title,
            patternCategory: pattern.category.rawValue,
            durationSeconds: durationSeconds,
            completedCycles: completedCycles,
            startedAt: Date().addingTimeInterval(-Double(durationSeconds)),
            completedAt: Date(),
            wasCompleted: wasCompleted,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            stressLevelBefore: stressBefore,
            stressLevelAfter: stressAfter,
            xpEarned: xp
        )
        
        let previousXP = computeStats().totalXP
        
        context.insert(record)
        try? context.save()
        
        // Update Quests before badges
        updateQuestsForSession(durationSeconds: durationSeconds, patternTitle: pattern.title)
        
        // Check for new badges
        checkBadges()
        
        let newXP = computeStats().totalXP
        checkLevelUp(previousXP: previousXP, currentXP: newXP)
        
        // Update widgets
        updateWidgetData()
        
        return record
    }
    
    // MARK: - Stats Computation
    
    func computeStats() -> UserStats {
        let sessions = fetchAllSessions()
        let today = Calendar.current.startOfDay(for: Date())
        
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let todaySessions = sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: today) }
        let todayMinutes = todaySessions.reduce(0.0) { $0 + $1.durationMinutes }
        
        let streak = calculateCurrentStreak(sessions: sessions)
        let longestStreak = calculateLongestStreak(sessions: sessions)
        let totalXP = sessions.reduce(0) { $0 + $1.xpEarned }
        let level = calculateLevel(xp: totalXP)
        let weeklyConsistency = calculateWeeklyConsistency(sessions: sessions)
        
        return UserStats(
            totalMinutes: totalMinutes,
            totalSessions: sessions.count,
            currentStreak: streak,
            longestStreak: longestStreak,
            todayMinutes: todayMinutes,
            todaySessions: todaySessions.count,
            level: level,
            totalXP: totalXP,
            weeklyConsistency: weeklyConsistency
        )
    }
    
    // MARK: - Fetching
    
    func fetchAllSessions() -> [SessionRecord] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchSessionsForRange(from start: Date, to end: Date) -> [SessionRecord] {
        guard let context = modelContext else { return [] }
        let predicate = #Predicate<SessionRecord> { session in
            session.startedAt >= start && session.startedAt <= end
        }
        var descriptor = FetchDescriptor<SessionRecord>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.startedAt, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchLastSession() -> SessionRecord? {
        guard let context = modelContext else { return nil }
        var descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
    
    func minutesPerDay(last days: Int) -> [(Date, Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Double)] = []
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)
            let sessions = fetchSessionsForRange(from: date, to: nextDay)
            let minutes = sessions.reduce(0.0) { $0 + $1.durationMinutes }
            result.append((date, minutes))
        }
        
        return result.reversed()
    }
    
    // MARK: - Heatmap Data
    
    func yearlyHeatmap() -> [Date: Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: today) else { return [:] }
        let sessions = fetchSessionsForRange(from: yearAgo, to: Date())
        
        var heatmap: [Date: Double] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            heatmap[day, default: 0] += session.durationMinutes
        }
        return heatmap
    }
    
    // MARK: - Advanced Analytics
    
    func patternDistribution() -> [(String, Double)] {
        let sessions = fetchAllSessions()
        var distribution: [String: Double] = [:]
        
        for session in sessions {
            distribution[session.patternTitle, default: 0] += session.durationMinutes
        }
        
        // Sort by duration descending
        return distribution.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    func timeOfDayPreference() -> String {
        let sessions = fetchAllSessions()
        guard !sessions.isEmpty else { return "None yet" }
        
        var morning = 0
        var afternoon = 0
        var evening = 0
        var night = 0
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startedAt)
            switch hour {
            case 6..<12: morning += 1
            case 12..<18: afternoon += 1
            case 18..<22: evening += 1
            default: night += 1
            }
        }
        
        let maxCount = max(morning, afternoon, evening, night)
        if maxCount == morning { return "Morning Breather 🌅" }
        if maxCount == afternoon { return "Afternoon Resetter ☀️" }
        if maxCount == evening { return "Evening Wind-down 🌆" }
        return "Night Owl 🦉"
    }
    
    // MARK: - Streak Calculation
    
    private func calculateCurrentStreak(sessions: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get unique session days
        var sessionDays = Set<Date>()
        for session in sessions {
            sessionDays.insert(calendar.startOfDay(for: session.startedAt))
        }
        
        var streak = 0
        var checkDate = today
        
        // If no session today, start checking from yesterday
        if !sessionDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
            // If yesterday also has no session, streak is 0
            if !sessionDays.contains(checkDate) { return 0 }
        }
        
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        
        return streak
    }
    
    private func calculateLongestStreak(sessions: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        var sessionDays = Set<Date>()
        for session in sessions {
            sessionDays.insert(calendar.startOfDay(for: session.startedAt))
        }
        
        let sortedDays = sessionDays.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        
        var longest = 1
        var current = 1
        
        for i in 1..<sortedDays.count {
            let prev = sortedDays[i - 1]
            let curr = sortedDays[i]
            
            if let expected = calendar.date(byAdding: .day, value: 1, to: prev), expected == curr {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        
        return longest
    }
    
    private func calculateWeeklyConsistency(sessions: [SessionRecord]) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var daysWithSessions = 0
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let hasSession = sessions.contains { calendar.isDate($0.startedAt, inSameDayAs: date) }
            if hasSession { daysWithSessions += 1 }
        }
        
        return Double(daysWithSessions) / 7.0
    }
    
    // MARK: - XP & Leveling
    
    private func calculateXP(durationSeconds: Int, wasCompleted: Bool) -> Int {
        let baseXP = durationSeconds / 60 * 10  // 10 XP per minute
        let completionBonus = wasCompleted ? 20 : 0
        return baseXP + completionBonus
    }
    
    func calculateLevel(xp: Int) -> Int {
        // Each level requires progressively more XP
        // Level 1: 0, Level 2: 100, Level 3: 250, Level 4: 500 ...
        let thresholds = [0, 100, 250, 500, 1000, 1750, 2750, 4000, 5500, 7500, 10000]
        for (i, threshold) in thresholds.enumerated().reversed() {
            if xp >= threshold { return i + 1 }
        }
        return 1
    }
    
    private func checkLevelUp(previousXP: Int, currentXP: Int) {
        let oldLevel = calculateLevel(xp: previousXP)
        let newLevel = calculateLevel(xp: currentXP)
        
        if newLevel > oldLevel {
            newLevelReached = newLevel
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showLevelUp = true
            }
            HapticsManager.shared.milestone()
        }
    }
    
    func xpForNextLevel(currentXP: Int) -> (current: Int, needed: Int) {
        let thresholds = [0, 100, 250, 500, 1000, 1750, 2750, 4000, 5500, 7500, 10000]
        let level = calculateLevel(xp: currentXP)
        if level >= thresholds.count { return (currentXP, currentXP) }
        let currentThreshold = thresholds[level - 1]
        let nextThreshold = thresholds[min(level, thresholds.count - 1)]
        return (currentXP - currentThreshold, nextThreshold - currentThreshold)
    }
    
    // MARK: - Badges
    
    func checkBadges() {
        guard let context = modelContext else { return }
        let stats = computeStats()
        let sessions = fetchAllSessions()
        
        // Fetch existing badges
        let descriptor = FetchDescriptor<BadgeRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let unlockedIds = Set(existing.map(\.badgeId))
        
        var newBadges: [String] = []
        
        // First Breath
        if !unlockedIds.contains("first_breath") && stats.totalSessions >= 1 {
            newBadges.append("first_breath")
        }
        
        // 3-Day Flow
        if !unlockedIds.contains("three_day_flow") && stats.currentStreak >= 3 {
            newBadges.append("three_day_flow")
        }
        
        // 7-Day Flow
        if !unlockedIds.contains("seven_day_flow") && stats.currentStreak >= 7 {
            newBadges.append("seven_day_flow")
        }
        
        // Monthly Master
        if !unlockedIds.contains("thirty_day_master") && stats.currentStreak >= 30 {
            newBadges.append("thirty_day_master")
        }
        
        // Deep Diver (10 minutes)
        if !unlockedIds.contains("ten_minutes") && stats.totalMinutes >= 10 {
            newBadges.append("ten_minutes")
        }
        
        // 100 Minutes
        if !unlockedIds.contains("hundred_minutes") && stats.totalMinutes >= 100 {
            newBadges.append("hundred_minutes")
        }
        
        // Night Owl
        if !unlockedIds.contains("night_owl") {
            let lateSession = sessions.first { session in
                Calendar.current.component(.hour, from: session.startedAt) >= 22
            }
            if lateSession != nil { newBadges.append("night_owl") }
        }
        
        // Early Bird
        if !unlockedIds.contains("early_bird") {
            let earlySession = sessions.first { session in
                Calendar.current.component(.hour, from: session.startedAt) < 7
            }
            if earlySession != nil { newBadges.append("early_bird") }
        }
        
        // Explorer (5 different patterns)
        if !unlockedIds.contains("explorer") {
            let uniquePatterns = Set(sessions.map(\.patternTitle))
            if uniquePatterns.count >= 5 { newBadges.append("explorer") }
        }
        
        // Zen Master (10 minute session)
        if !unlockedIds.contains("zen_master") {
            let longSession = sessions.first { $0.durationSeconds >= 600 }
            if longSession != nil { newBadges.append("zen_master") }
        }
        
        // Weekend Warrior
        if !unlockedIds.contains("weekend_warrior") {
            let hasSaturday = sessions.contains { Calendar.current.component(.weekday, from: $0.startedAt) == 7 }
            let hasSunday = sessions.contains { Calendar.current.component(.weekday, from: $0.startedAt) == 1 }
            if hasSaturday && hasSunday { newBadges.append("weekend_warrior") }
        }
        
        // Consistency King
        if !unlockedIds.contains("consistency_king") && stats.currentStreak >= 50 {
            newBadges.append("consistency_king")
        }
        
        // Mindful Morning
        if !unlockedIds.contains("mindful_morning") {
            let earlySessions = sessions.filter { Calendar.current.component(.hour, from: $0.startedAt) < 9 }
            if earlySessions.count >= 5 { newBadges.append("mindful_morning") }
        }
        
        for badgeId in newBadges {
            context.insert(BadgeRecord(badgeId: badgeId))
        }
        
        try? context.save()
    }
    
    func fetchUnlockedBadgeIds() -> Set<String> {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<BadgeRecord>()
        let records = (try? context.fetch(descriptor)) ?? []
        return Set(records.map(\.badgeId))
    }
    
    // MARK: - Custom Patterns
    
    func saveCustomPattern(_ pattern: BreathingPattern) {
        guard let context = modelContext else { return }
        context.insert(CustomPatternRecord(from: pattern))
        try? context.save()
    }
    
    func fetchCustomPatterns() -> [BreathingPattern] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CustomPatternRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return ((try? context.fetch(descriptor)) ?? []).map { $0.toPattern() }
    }
    
    func deleteCustomPattern(id: UUID) {
        guard let context = modelContext else { return }
        let predicate = #Predicate<CustomPatternRecord> { $0.id == id }
        let descriptor = FetchDescriptor<CustomPatternRecord>(predicate: predicate)
        if let record = (try? context.fetch(descriptor))?.first {
            context.delete(record)
            try? context.save()
        }
    }
    
    // MARK: - Check-ins
    
    func saveCheckIn(_ checkIn: DailyCheckIn) {
        guard let context = modelContext else { return }
        
        let previousXP = computeStats().totalXP
        
        context.insert(checkIn)
        try? context.save()
        
        updateQuestsForCheckIn()
        
        let newXP = computeStats().totalXP
        checkLevelUp(previousXP: previousXP, currentXP: newXP)
    }
    
    func todayCheckIn() -> DailyCheckIn? {
        guard let context = modelContext else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86400)
        let predicate = #Predicate<DailyCheckIn> { $0.date >= today && $0.date < tomorrow }
        var descriptor = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
    
    func recentCheckIns(days: Int) -> [DailyCheckIn] {
        guard let context = modelContext else { return [] }
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<DailyCheckIn> { $0.date >= startDate }
        var descriptor = FetchDescriptor<DailyCheckIn>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Daily Quests
    
    func fetchDailyQuests() -> [DailyQuestRecord] {
        guard let context = modelContext else { return [] }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86400)
        let predicate = #Predicate<DailyQuestRecord> { $0.date >= today && $0.date < tomorrow }
        var descriptor = FetchDescriptor<DailyQuestRecord>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.title)]
        
        let quests = (try? context.fetch(descriptor)) ?? []
        if quests.isEmpty {
            return generateDailyQuests()
        }
        return quests
    }
    
    private func generateDailyQuests() -> [DailyQuestRecord] {
        guard let context = modelContext else { return [] }
        let today = Calendar.current.startOfDay(for: Date())
        
        let quests = [
            DailyQuestRecord(id: UUID().uuidString, title: "Protocol Duration Target", descriptionText: "Maintain regulation for 5 minutes", icon: "clock.fill", xpReward: 50, type: "duration", targetValue: 300, date: today),
            DailyQuestRecord(id: UUID().uuidString, title: "Biofeedback Synchronization", descriptionText: "Log your physiological state", icon: "heart.text.clipboard", xpReward: 30, type: "checkin", targetValue: 1, date: today),
            DailyQuestRecord(id: UUID().uuidString, title: "Protocol Diversity", descriptionText: "Complete 2 different protocols", icon: "wind", xpReward: 40, type: "session_count", targetValue: 2, date: today)
        ]
        
        for quest in quests {
            context.insert(quest)
        }
        try? context.save()
        return quests
    }
    
    private func updateQuestsForSession(durationSeconds: Int, patternTitle: String) {
        guard let context = modelContext else { return }
        let quests = fetchDailyQuests()
        var updated = false
        
        for quest in quests where !quest.isCompleted {
            if quest.type == "duration" {
                quest.currentValue += durationSeconds
            } else if quest.type == "session_count" {
                quest.currentValue += 1
            }
            
            if quest.currentValue >= quest.targetValue {
                quest.currentValue = quest.targetValue
                quest.isCompleted = true
                
                // Award XP for quest completion
                let record = SessionRecord(
                    patternTitle: "Quest Completed",
                    patternCategory: "quest",
                    durationSeconds: 0,
                    xpEarned: quest.xpReward
                )
                context.insert(record)
            }
            updated = true
        }
        
        if updated { try? context.save() }
    }
    
    private func updateQuestsForCheckIn() {
        guard let context = modelContext else { return }
        let quests = fetchDailyQuests()
        var updated = false
        
        for quest in quests where !quest.isCompleted && quest.type == "checkin" {
            quest.currentValue += 1
            if quest.currentValue >= quest.targetValue {
                quest.currentValue = quest.targetValue
                quest.isCompleted = true
                
                let record = SessionRecord(
                    patternTitle: "Quest Completed",
                    patternCategory: "quest",
                    durationSeconds: 0,
                    xpEarned: quest.xpReward
                )
                context.insert(record)
            }
            updated = true
        }
        
        if updated { try? context.save() }
    }
    
    // MARK: - Data Export
    
    func exportData() -> Data? {
        let sessions = fetchAllSessions()
        
        struct ExportPayload: Codable {
            let sessions: [SessionExport]
            let exportDate: Date
        }
        
        struct SessionExport: Codable {
            let pattern: String
            let category: String
            let durationSeconds: Int
            let startedAt: Date
            let completedAt: Date?
            let wasCompleted: Bool
            let moodBefore: String?
            let moodAfter: String?
        }
        
        let payload = ExportPayload(
            sessions: sessions.map {
                SessionExport(
                    pattern: $0.patternTitle,
                    category: $0.patternCategory,
                    durationSeconds: $0.durationSeconds,
                    startedAt: $0.startedAt,
                    completedAt: $0.completedAt,
                    wasCompleted: $0.wasCompleted,
                    moodBefore: $0.moodBefore,
                    moodAfter: $0.moodAfter
                )
            },
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(payload)
    }
    
    // MARK: - Biometric Insights
    
    func generateBiometricInsight() -> String {
        guard let checkIn = todayCheckIn() else {
            return "Complete your daily assessment to unlock physiological insights."
        }
        
        let readiness = checkIn.readinessScore
        
        if readiness >= 80 {
            return "Optimal Readiness (\(readiness)%). Your nervous system is primed. Recommended: 'Focus' or 'Energy' protocols to leverage your metabolic state."
        } else if readiness >= 60 {
            return "Moderate Readiness (\(readiness)%). Balanced autonomic tone. Any protocol is suitable today."
        } else {
            if checkIn.sleepQuality <= 2 {
                return "Low Readiness (\(readiness)%). Sleep architecture is fragmented. Recommended: '3-6-9 Breathing' tonight to restore circadian rhythm."
            } else if checkIn.stressLevel >= 4 {
                return "Low Readiness (\(readiness)%). High cortisol index detected. Recommended: 'Pure Diaphragmatic' to activate vagal tone."
            } else {
                return "Low Readiness (\(readiness)%). Energy depleted. Recommended: Gentle 'Calm' protocols to avoid autonomic overreach."
            }
        }
    }
    
    // MARK: - Data Deletion
    
    func resetAllData() {
        guard let context = modelContext else { return }
        
        do {
            try context.delete(model: SessionRecord.self)
            try context.delete(model: DailyCheckIn.self)
            try context.delete(model: BadgeRecord.self)
            try context.delete(model: CustomPatternRecord.self)
            try context.save()
            
            updateWidgetData()
        } catch {
            print("Failed to reset SwiftData: \(error)")
        }
    }
    
    // MARK: - Widget Data
    
    private func updateWidgetData() {
        let stats = computeStats()
        let lastSession = fetchLastSession()
        let last7Days = minutesPerDay(last: 7).map { $0.1 }
        
        let widgetData = WidgetData(
            currentStreak: stats.currentStreak,
            todayMinutes: stats.todayMinutes,
            todaySessions: stats.todaySessions,
            totalMinutes: stats.totalMinutes,
            totalSessions: stats.totalSessions,
            level: stats.level,
            totalXP: stats.totalXP,
            weeklyConsistency: stats.weeklyConsistency,
            lastSessionPattern: lastSession?.patternTitle,
            lastSessionDate: lastSession?.startedAt,
            last7DaysMinutes: last7Days,
            updatedAt: Date()
        )
        
        WidgetDataProvider.write(widgetData)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
