import Foundation
import SwiftData

// MARK: - Session Record (SwiftData)

@Model
final class SessionRecord {
    var id: UUID
    var patternTitle: String
    var patternCategory: String
    var durationSeconds: Int
    var completedCycles: Int
    var startedAt: Date
    var completedAt: Date?
    var wasCompleted: Bool
    var moodBefore: String?
    var moodAfter: String?
    var stressLevelBefore: Int?
    var stressLevelAfter: Int?
    var xpEarned: Int
    
    init(
        patternTitle: String,
        patternCategory: String,
        durationSeconds: Int,
        completedCycles: Int = 0,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        wasCompleted: Bool = false,
        moodBefore: String? = nil,
        moodAfter: String? = nil,
        stressLevelBefore: Int? = nil,
        stressLevelAfter: Int? = nil,
        xpEarned: Int = 0
    ) {
        self.id = UUID()
        self.patternTitle = patternTitle
        self.patternCategory = patternCategory
        self.durationSeconds = durationSeconds
        self.completedCycles = completedCycles
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.wasCompleted = wasCompleted
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.stressLevelBefore = stressLevelBefore
        self.stressLevelAfter = stressLevelAfter
        self.xpEarned = xpEarned
    }
    
    var durationMinutes: Double {
        Double(durationSeconds) / 60.0
    }
}

// MARK: - Daily Check-In (SwiftData)

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date
    var stressLevel: Int   // 1-5
    var moodLevel: Int     // 1-5
    var energyLevel: Int   // 1-5
    var sleepQuality: Int  // 1-5
    var notes: String?
    
    init(
        date: Date = Date(),
        stressLevel: Int = 3,
        moodLevel: Int = 3,
        energyLevel: Int = 3,
        sleepQuality: Int = 3,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.stressLevel = stressLevel
        self.moodLevel = moodLevel
        self.energyLevel = energyLevel
        self.sleepQuality = sleepQuality
        self.notes = notes
    }
}

// MARK: - Badge / Achievement

@Model
final class BadgeRecord {
    var id: UUID
    var badgeId: String
    var unlockedAt: Date
    
    init(badgeId: String) {
        self.id = UUID()
        self.badgeId = badgeId
        self.unlockedAt = Date()
    }
}

// MARK: - Custom Pattern Storage

@Model
final class CustomPatternRecord {
    var id: UUID
    var title: String
    var inhaleSeconds: Double
    var hold1Seconds: Double
    var exhaleSeconds: Double
    var hold2Seconds: Double
    var icon: String
    var colorHex: Int
    var mascotMood: String
    var createdAt: Date
    
    init(from pattern: BreathingPattern) {
        self.id = pattern.id
        self.title = pattern.title
        self.inhaleSeconds = pattern.inhaleSeconds
        self.hold1Seconds = pattern.hold1Seconds
        self.exhaleSeconds = pattern.exhaleSeconds
        self.hold2Seconds = pattern.hold2Seconds
        self.icon = pattern.icon
        self.colorHex = Int(pattern.colorHex)
        self.mascotMood = pattern.mascotMood.rawValue
        self.createdAt = Date()
    }
    
    func toPattern() -> BreathingPattern {
        BreathingPattern(
            id: id,
            title: title,
            inhale: inhaleSeconds,
            hold1: hold1Seconds,
            exhale: exhaleSeconds,
            hold2: hold2Seconds,
            icon: icon,
            colorHex: UInt(colorHex),
            category: .custom,
            isCustom: true,
            mascotMood: MascotMood(rawValue: mascotMood) ?? .calm
        )
    }
}

// MARK: - User Stats (Computed helper)

struct UserStats {
    var totalMinutes: Int
    var totalSessions: Int
    var currentStreak: Int
    var longestStreak: Int
    var todayMinutes: Double
    var todaySessions: Int
    var level: Int
    var totalXP: Int
    var weeklyConsistency: Double
}

// MARK: - Badge Definition

struct BadgeDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: String
    let xpReward: Int
    
    static let allBadges: [BadgeDefinition] = [
        BadgeDefinition(id: "first_breath", title: "First Breath", description: "Complete your first session", icon: "lungs.fill", requirement: "1 session", xpReward: 50),
        BadgeDefinition(id: "three_day_flow", title: "3-Day Flow", description: "Breathe for 3 days in a row", icon: "flame.fill", requirement: "3 day streak", xpReward: 100),
        BadgeDefinition(id: "seven_day_flow", title: "7-Day Flow", description: "A full week of breathing", icon: "flame.fill", requirement: "7 day streak", xpReward: 200),
        BadgeDefinition(id: "thirty_day_master", title: "Monthly Master", description: "30 days of consistency", icon: "crown.fill", requirement: "30 day streak", xpReward: 500),
        BadgeDefinition(id: "ten_minutes", title: "Deep Diver", description: "Breathe for 10 total minutes", icon: "water.waves", requirement: "10 minutes", xpReward: 50),
        BadgeDefinition(id: "hundred_minutes", title: "100 Minutes", description: "100 minutes of mindful breathing", icon: "sparkles", requirement: "100 minutes", xpReward: 300),
        BadgeDefinition(id: "calm_master", title: "Calm Master", description: "Complete 20 calm sessions", icon: "leaf.fill", requirement: "20 calm sessions", xpReward: 250),
        BadgeDefinition(id: "night_owl", title: "Night Owl", description: "Complete a session after 10 PM", icon: "moon.stars.fill", requirement: "Late session", xpReward: 75),
        BadgeDefinition(id: "early_bird", title: "Early Bird", description: "Complete a session before 7 AM", icon: "sunrise.fill", requirement: "Early session", xpReward: 75),
        BadgeDefinition(id: "explorer", title: "Explorer", description: "Try 5 different breathing patterns", icon: "map.fill", requirement: "5 patterns", xpReward: 150),
        BadgeDefinition(id: "custom_creator", title: "Custom Creator", description: "Create your first custom pattern", icon: "wand.and.stars", requirement: "1 custom pattern", xpReward: 100),
        BadgeDefinition(id: "zen_master", title: "Zen Master", description: "Complete a 10-minute session", icon: "figure.mind.and.body", requirement: "10 min session", xpReward: 200),
    ]
}

// MARK: - Companion Unlockable

struct CompanionUnlockable: Identifiable {
    let id: String
    let title: String
    let description: String
    let requiredLevel: Int
    let icon: String
}

enum CompanionUnlockables {
    static let expressions: [CompanionUnlockable] = [
        CompanionUnlockable(id: "wink", title: "Wink", description: "Breedy winks at you", requiredLevel: 2, icon: "😉"),
        CompanionUnlockable(id: "sparkle", title: "Sparkle Eyes", description: "Breedy's eyes sparkle", requiredLevel: 3, icon: "✨"),
        CompanionUnlockable(id: "rainbow", title: "Rainbow Aura", description: "A rainbow aura appears", requiredLevel: 5, icon: "🌈"),
        CompanionUnlockable(id: "crown", title: "Crown", description: "A tiny crown for Breedy", requiredLevel: 7, icon: "👑"),
        CompanionUnlockable(id: "butterfly", title: "Butterfly Friend", description: "A butterfly follows Breedy", requiredLevel: 10, icon: "🦋"),
    ]
}
