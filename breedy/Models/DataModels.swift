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
    
    var readinessScore: Int {
        // Formula: Sleep + Energy + Mood + Inverted Stress (6 - Stress).
        // Max possible is 5 + 5 + 5 + 5 = 20.
        // Multiply by 5 to get a 0-100% score.
        let invertedStress = 6 - stressLevel
        let total = sleepQuality + energyLevel + moodLevel + invertedStress
        return Int((Double(total) / 20.0) * 100)
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

// MARK: - Daily Quest Storage

@Model
final class DailyQuestRecord {
    var id: String
    var title: String
    var descriptionText: String
    var icon: String
    var xpReward: Int
    var isCompleted: Bool
    var date: Date
    var type: String // e.g., "duration", "pattern", "checkin", "timeOfDay"
    var targetValue: Int
    var currentValue: Int
    
    init(id: String, title: String, descriptionText: String, icon: String, xpReward: Int, type: String, targetValue: Int, date: Date = Date()) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.icon = icon
        self.xpReward = xpReward
        self.isCompleted = false
        self.date = date
        self.type = type
        self.targetValue = targetValue
        self.currentValue = 0
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

enum BadgeTier: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
}

struct BadgeDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: String
    let xpReward: Int
    let tier: BadgeTier
    
    static let allBadges: [BadgeDefinition] = [
        BadgeDefinition(id: "first_breath", title: "Protocol Initiation", description: "Complete your first clinical session", icon: "lungs.fill", requirement: "1 session", xpReward: 50, tier: .common),
        BadgeDefinition(id: "three_day_flow", title: "3-Day Adherence", description: "Maintain regulation for 3 days", icon: "flame.fill", requirement: "3 day streak", xpReward: 100, tier: .common),
        BadgeDefinition(id: "seven_day_flow", title: "7-Day Adherence", description: "A full week of neuroplasticity", icon: "flame.fill", requirement: "7 day streak", xpReward: 200, tier: .rare),
        BadgeDefinition(id: "thirty_day_master", title: "Monthly Sustenance", description: "30 days of autonomic balance", icon: "crown.fill", requirement: "30 day streak", xpReward: 500, tier: .epic),
        BadgeDefinition(id: "ten_minutes", title: "Deep Regulation", description: "10 total minutes of breathwork", icon: "water.waves", requirement: "10 minutes", xpReward: 50, tier: .common),
        BadgeDefinition(id: "hundred_minutes", title: "Extended Regulation", description: "100 total minutes of breathwork", icon: "sparkles", requirement: "100 minutes", xpReward: 300, tier: .rare),
        BadgeDefinition(id: "calm_master", title: "Vagal Master", description: "Complete 20 parasympathetic sessions", icon: "leaf.fill", requirement: "20 calm sessions", xpReward: 250, tier: .epic),
        BadgeDefinition(id: "night_owl", title: "Circadian Late Shift", description: "Evening down-regulation protocol", icon: "moon.stars.fill", requirement: "Late session", xpReward: 75, tier: .rare),
        BadgeDefinition(id: "early_bird", title: "Circadian Early Shift", description: "Morning activation protocol", icon: "sunrise.fill", requirement: "Early session", xpReward: 75, tier: .rare),
        BadgeDefinition(id: "explorer", title: "Protocol Diversity", description: "Utilize 5 different protocols", icon: "map.fill", requirement: "5 patterns", xpReward: 150, tier: .epic),
        BadgeDefinition(id: "custom_creator", title: "Custom Prescriber", description: "Design a custom protocol", icon: "wand.and.stars", requirement: "1 custom pattern", xpReward: 100, tier: .rare),
        BadgeDefinition(id: "zen_master", title: "Sustained Autonomic Regulation", description: "Complete a 10-minute continuous protocol", icon: "figure.mind.and.body", requirement: "10 min session", xpReward: 200, tier: .epic),
        BadgeDefinition(id: "weekend_warrior", title: "Continuous Cycle Maintenance", description: "Maintain protocol on Sat & Sun", icon: "calendar.badge.clock", requirement: "Weekend sessions", xpReward: 150, tier: .rare),
        BadgeDefinition(id: "consistency_king", title: "Homeostasis Expert", description: "Reach a 50-day adherence streak", icon: "crown.fill", requirement: "50 day streak", xpReward: 1000, tier: .legendary),
        BadgeDefinition(id: "mindful_morning", title: "Morning Priming", description: "5 early morning activation sessions", icon: "sun.max.fill", requirement: "5 early sessions", xpReward: 200, tier: .epic)
    ]
}

// MARK: - Companion Aura

struct CompanionAura: Identifiable {
    let id: String
    let title: String
    let description: String
    let requiredLevel: Int
    let colorHex: UInt
}

enum CompanionAuras {
    static let allAuras: [CompanionAura] = [
        CompanionAura(id: "default", title: "Parasympathetic Baseline", description: "Natural autonomic state", requiredLevel: 1, colorHex: 0x5C7C8A),
        CompanionAura(id: "golden", title: "High Coherence", description: "Heart-brain synchronization", requiredLevel: 3, colorHex: 0xFFD700),
        CompanionAura(id: "cherry", title: "Vagal Tone Enhancement", description: "Optimized parasympathetic response", requiredLevel: 5, colorHex: 0xFFB7C5),
        CompanionAura(id: "mint", title: "Sympathetic Activation", description: "Controlled alertness", requiredLevel: 7, colorHex: 0x98FF98),
        CompanionAura(id: "amethyst", title: "Deep Delta State", description: "Profound restorative resonance", requiredLevel: 10, colorHex: 0x9966CC),
        CompanionAura(id: "obsidian", title: "Absolute Homeostasis", description: "Perfect physiological equilibrium", requiredLevel: 15, colorHex: 0x2A2A2A)
    ]
}
