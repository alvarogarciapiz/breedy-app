import SwiftUI

// MARK: - Breathing Phase

enum BreathPhase: String, Codable, CaseIterable {
    case inhale
    case hold1
    case exhale
    case hold2
    
    var displayName: String {
        switch self {
        case .inhale:  return "Inhale"
        case .hold1:   return "Hold"
        case .exhale:  return "Exhale"
        case .hold2:   return "Hold"
        }
    }
    
    var icon: String {
        switch self {
        case .inhale:  return "arrow.up.circle.fill"
        case .hold1:   return "pause.circle.fill"
        case .exhale:  return "arrow.down.circle.fill"
        case .hold2:   return "pause.circle.fill"
        }
    }
    
    var instruction: String {
        switch self {
        case .inhale:  return "Breathe in slowly"
        case .hold1:   return "Hold gently"
        case .exhale:  return "Release slowly"
        case .hold2:   return "Rest"
        }
    }
    
    var orbScale: CGFloat {
        switch self {
        case .inhale:  return 1.0
        case .hold1:   return 1.0
        case .exhale:  return 0.6
        case .hold2:   return 0.6
        }
    }
}

// MARK: - Breathing Pattern

struct BreathingPattern: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var inhaleSeconds: Double
    var hold1Seconds: Double
    var exhaleSeconds: Double
    var hold2Seconds: Double
    var icon: String
    var colorHex: UInt
    var category: PatternCategory
    var isCustom: Bool
    var mascotMood: MascotMood
    
    var cycleDuration: Double {
        inhaleSeconds + hold1Seconds + exhaleSeconds + hold2Seconds
    }
    
    var phases: [(BreathPhase, Double)] {
        var result: [(BreathPhase, Double)] = []
        result.append((.inhale, inhaleSeconds))
        if hold1Seconds > 0 { result.append((.hold1, hold1Seconds)) }
        result.append((.exhale, exhaleSeconds))
        if hold2Seconds > 0 { result.append((.hold2, hold2Seconds)) }
        return result
    }
    
    var accentColor: Color {
        Color(hex: colorHex)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        inhale: Double,
        hold1: Double,
        exhale: Double,
        hold2: Double,
        icon: String = "wind",
        colorHex: UInt = 0x0A72EF,
        category: PatternCategory = .calm,
        isCustom: Bool = false,
        mascotMood: MascotMood = .calm
    ) {
        self.id = id
        self.title = title
        self.inhaleSeconds = inhale
        self.hold1Seconds = hold1
        self.exhaleSeconds = exhale
        self.hold2Seconds = hold2
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.isCustom = isCustom
        self.mascotMood = mascotMood
    }
}

// MARK: - Pattern Category

enum PatternCategory: String, Codable, CaseIterable {
    case calm = "Calm"
    case focus = "Focus"
    case sleep = "Sleep"
    case energy = "Energy"
    case anxiety = "Anxiety Relief"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .calm:    return "leaf.fill"
        case .focus:   return "scope"
        case .sleep:   return "moon.fill"
        case .energy:  return "bolt.fill"
        case .anxiety: return "heart.fill"
        case .custom:  return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .calm:    return BDDesign.Colors.accentCalm
        case .focus:   return BDDesign.Colors.accentFocus
        case .sleep:   return BDDesign.Colors.accentSleep
        case .energy:  return BDDesign.Colors.accentEnergy
        case .anxiety: return BDDesign.Colors.accentAnxiety
        case .custom:  return BDDesign.Colors.gray500
        }
    }
}

// MARK: - Session Duration Mode

enum SessionDurationMode: Codable, Hashable {
    case timed(seconds: Int)
    case cycles(count: Int)
}

// MARK: - Session Configuration

struct SessionConfiguration: Codable, Identifiable {
    let id: UUID
    let pattern: BreathingPattern
    let durationMode: SessionDurationMode
    let soundEnabled: Bool
    let hapticsEnabled: Bool
    let voiceCuesEnabled: Bool
    let zenMode: Bool
    
    init(
        id: UUID = UUID(),
        pattern: BreathingPattern,
        durationMode: SessionDurationMode = .timed(seconds: 300),
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        voiceCuesEnabled: Bool = false,
        zenMode: Bool = false
    ) {
        self.id = id
        self.pattern = pattern
        self.durationMode = durationMode
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.voiceCuesEnabled = voiceCuesEnabled
        self.zenMode = zenMode
    }
}

// MARK: - Mood State

enum MoodState: String, Codable, CaseIterable, Identifiable {
    case calm = "Calm"
    case focus = "Focus"
    case sleep = "Sleep"
    case energy = "Energy"
    case anxietyRelief = "Anxiety Relief"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .calm:          return "leaf.fill"
        case .focus:         return "scope"
        case .sleep:         return "moon.fill"
        case .energy:        return "bolt.fill"
        case .anxietyRelief: return "heart.fill"
        }
    }
    
    var color: Color {
        BDDesign.Colors.moodColor(for: self)
    }
    
    var greeting: String {
        switch self {
        case .calm:          return "Let's find your calm"
        case .focus:         return "Time to sharpen focus"
        case .sleep:         return "Prepare for rest"
        case .energy:        return "Let's get energized"
        case .anxietyRelief: return "You're safe here"
        }
    }
    
    var suggestedPattern: BreathingPattern {
        switch self {
        case .calm:          return BreathingPresets.coherentBreathing
        case .focus:         return BreathingPresets.boxBreathing
        case .sleep:         return BreathingPresets.fourSevenEight
        case .energy:        return BreathingPresets.energyBreath
        case .anxietyRelief: return BreathingPresets.anxietyReset
        }
    }
}

// MARK: - Mascot Mood

enum MascotMood: String, Codable, CaseIterable {
    case calm
    case happy
    case sleepy
    case energetic
    case supportive
    case celebrating
    case meditating
    case breathing
    
    var expression: String {
        switch self {
        case .calm:        return "😌"
        case .happy:       return "😊"
        case .sleepy:      return "😴"
        case .energetic:   return "⚡"
        case .supportive:  return "🤗"
        case .celebrating: return "🎉"
        case .meditating:  return "🧘"
        case .breathing:   return "🌬️"
        }
    }
}

// MARK: - Breathing Presets

enum BreathingPresets {
    static let boxBreathing = BreathingPattern(
        title: "Box Breathing",
        inhale: 4, hold1: 4, exhale: 4, hold2: 4,
        icon: "square",
        colorHex: 0x0A72EF,
        category: .focus,
        mascotMood: .calm
    )
    
    static let fourSevenEight = BreathingPattern(
        title: "4-7-8",
        inhale: 4, hold1: 7, exhale: 8, hold2: 0,
        icon: "moon.fill",
        colorHex: 0x7928CA,
        category: .sleep,
        mascotMood: .sleepy
    )
    
    static let coherentBreathing = BreathingPattern(
        title: "Coherent Breathing",
        inhale: 5.5, hold1: 0, exhale: 5.5, hold2: 0,
        icon: "waveform.path",
        colorHex: 0x0A72EF,
        category: .calm,
        mascotMood: .meditating
    )
    
    static let physiologicalSigh = BreathingPattern(
        title: "Physiological Sigh",
        inhale: 3, hold1: 1, exhale: 6, hold2: 0,
        icon: "wind",
        colorHex: 0xDE1D8D,
        category: .anxiety,
        mascotMood: .supportive
    )
    
    static let deepCalm = BreathingPattern(
        title: "Deep Calm",
        inhale: 6, hold1: 2, exhale: 8, hold2: 2,
        icon: "water.waves",
        colorHex: 0x0072F5,
        category: .calm,
        mascotMood: .calm
    )
    
    static let energyBreath = BreathingPattern(
        title: "Energy Breath",
        inhale: 3, hold1: 0, exhale: 3, hold2: 0,
        icon: "bolt.fill",
        colorHex: 0xFF5B4F,
        category: .energy,
        mascotMood: .energetic
    )
    
    static let sleepWindDown = BreathingPattern(
        title: "Sleep Wind Down",
        inhale: 4, hold1: 4, exhale: 6, hold2: 2,
        icon: "moon.stars.fill",
        colorHex: 0x7928CA,
        category: .sleep,
        mascotMood: .sleepy
    )
    
    static let anxietyReset = BreathingPattern(
        title: "Anxiety Reset",
        inhale: 4, hold1: 2, exhale: 6, hold2: 0,
        icon: "heart.fill",
        colorHex: 0xDE1D8D,
        category: .anxiety,
        mascotMood: .supportive
    )
    
    static let allPresets: [BreathingPattern] = [
        boxBreathing, fourSevenEight, coherentBreathing,
        physiologicalSigh, deepCalm, energyBreath,
        sleepWindDown, anxietyReset
    ]
    
    static func presetsFor(mood: MoodState) -> [BreathingPattern] {
        switch mood {
        case .calm:          return [coherentBreathing, deepCalm, physiologicalSigh]
        case .focus:         return [boxBreathing, coherentBreathing]
        case .sleep:         return [fourSevenEight, sleepWindDown]
        case .energy:        return [energyBreath, boxBreathing]
        case .anxietyRelief: return [anxietyReset, physiologicalSigh, deepCalm]
        }
    }
}
