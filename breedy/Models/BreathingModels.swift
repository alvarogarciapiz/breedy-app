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
    
    // Science metadata
    var description: String
    var scienceDetail: String
    var benefitTags: [String]
    var scienceBadge: String
    
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
        colorHex: UInt = 0x5C7C8A,
        category: PatternCategory = .calm,
        isCustom: Bool = false,
        mascotMood: MascotMood = .calm,
        description: String = "",
        scienceDetail: String = "",
        benefitTags: [String] = [],
        scienceBadge: String = ""
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
        self.description = description
        self.scienceDetail = scienceDetail
        self.benefitTags = benefitTags
        self.scienceBadge = scienceBadge
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
        case .energy:        return BreathingPresets.kapalabhati
        case .anxietyRelief: return BreathingPresets.physiologicalSigh
        }
    }
}

// MARK: - Mascot Mood

enum MascotMood: String, Codable, CaseIterable {
    case calm
    case happy
    case sleepy
    case happySleep
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
        case .happySleep:  return "😇"
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
        icon: "square.fill",
        colorHex: 0x4A7B76,
        category: .focus,
        mascotMood: .calm,
        description: "Inhale, hold, exhale, and hold empty for equal durations.",
        scienceDetail: "Regulates heart rate, stabilizes the autonomic nervous system, and clears excess adrenaline in high-stress situations.",
        benefitTags: ["HRV ↑", "Cortisol ↓", "Focus"],
        scienceBadge: "Tactical"
    )
    
    static let fourSevenEight = BreathingPattern(
        title: "4-7-8 Breathing",
        inhale: 4, hold1: 7, exhale: 8, hold2: 0,
        icon: "moon.stars.fill",
        colorHex: 0x635D7A,
        category: .sleep,
        mascotMood: .sleepy,
        description: "Natural tranquilizer for the nervous system, ideal for sleep.",
        scienceDetail: "Prolonged exhalation directly stimulates the vagus nerve. Highly effective against acute insomnia.",
        benefitTags: ["Sleep", "Vagal Tone", "Insomnia ↓"],
        scienceBadge: "Clinical"
    )
    
    static let physiologicalSigh = BreathingPattern(
        title: "Physiological Sigh",
        inhale: 3, hold1: 1, exhale: 6, hold2: 0,
        icon: "lungs.fill",
        colorHex: 0xC88A8A,
        category: .anxiety,
        mascotMood: .supportive,
        description: "Double sharp inhale followed by a long exhale.",
        scienceDetail: "Rapidly offloads carbon dioxide and activates the parasympathetic nervous system, reducing anxiety in real-time.",
        benefitTags: ["Anxiety ↓", "CO2 Balance"],
        scienceBadge: "Neurobiology"
    )
    
    static let coherentBreathing = BreathingPattern(
        title: "Coherent Breathing",
        inhale: 5.5, hold1: 0, exhale: 5.5, hold2: 0,
        icon: "waveform.path",
        colorHex: 0x5C7C8A,
        category: .calm,
        mascotMood: .calm,
        description: "Continuous rhythmic breathing at 5.5 breaths per minute.",
        scienceDetail: "Synchronizes respiratory and cardiovascular systems, maximizing Heart Rate Variability (HRV) and biological resilience.",
        benefitTags: ["Max HRV", "Resilience", "Balance"],
        scienceBadge: "Gold Standard"
    )
    
    static let wimHof = BreathingPattern(
        title: "Wim Hof Method",
        inhale: 1.5, hold1: 0, exhale: 1.5, hold2: 0,
        icon: "snowflake",
        colorHex: 0x5C7C8A,
        category: .energy,
        mascotMood: .energetic,
        description: "Simulated rapid cycles for quick activation.",
        scienceDetail: "Induces controlled respiratory alkalosis, releasing adrenaline and improving physical and thermal stress tolerance.",
        benefitTags: ["Energy ↑", "Adrenaline ↑", "Alkalosis"],
        scienceBadge: "Performance"
    )
    
    static let nadiShodhana = BreathingPattern(
        title: "Nadi Shodhana",
        inhale: 4, hold1: 2, exhale: 6, hold2: 2,
        icon: "arrow.triangle.2.circlepath",
        colorHex: 0x8A8AC8,
        category: .anxiety,
        mascotMood: .meditating,
        description: "Alternate nostril breathing (simulated via guided rhythm).",
        scienceDetail: "Balances cerebral hemisphere activity, regulates blood pressure, and lowers baseline anxiety before focused tasks.",
        benefitTags: ["Balance", "Anxiety ↓"],
        scienceBadge: "Traditional"
    )
    
    static let buteyko = BreathingPattern(
        title: "Buteyko Method",
        inhale: 3, hold1: 0, exhale: 4, hold2: 3,
        icon: "nose",
        colorHex: 0x7F9F80,
        category: .calm,
        mascotMood: .calm,
        description: "Volume reduction with pauses for CO2 tolerance.",
        scienceDetail: "Created to recover chemical tolerance to carbon dioxide. Promotes shallow breathing that improves cellular oxygenation (Bohr Effect).",
        benefitTags: ["CO2 Tolerance", "Oxygenation"],
        scienceBadge: "Physiology"
    )
    
    static let kapalabhati = BreathingPattern(
        title: "Kapalabhati",
        inhale: 1, hold1: 0, exhale: 1, hold2: 0,
        icon: "flame.fill",
        colorHex: 0xD26060,
        category: .energy,
        mascotMood: .energetic,
        description: "Breath of fire: Active exhale and abdominal contraction.",
        scienceDetail: "Short, forceful exhalations stimulate the sympathetic nervous system, generating immediate body heat and alertness.",
        benefitTags: ["Heat ↑", "Alertness ↑"],
        scienceBadge: "Traditional"
    )
    
    static let bhastrika = BreathingPattern(
        title: "Bhastrika (Bellows)",
        inhale: 1.5, hold1: 0, exhale: 1.5, hold2: 0,
        icon: "wind",
        colorHex: 0xD26060,
        category: .energy,
        mascotMood: .energetic,
        description: "Deep symmetric forced inhalations and exhalations.",
        scienceDetail: "Intensely activates the central nervous system, temporarily saturating blood oxygen. Used for extreme pre-workout activation.",
        benefitTags: ["Extreme Activation", "Max Oxygen"],
        scienceBadge: "Sports"
    )
    
    static let ujjayi = BreathingPattern(
        title: "Ujjayi (Ocean Breath)",
        inhale: 5, hold1: 0, exhale: 5, hold2: 0,
        icon: "water.waves",
        colorHex: 0x4A7B76,
        category: .focus,
        mascotMood: .meditating,
        description: "Slow breathing with slight glottal friction.",
        scienceDetail: "Laryngeal resistance prolongs respiratory phases, stimulates vagal afferents in the throat, and fosters deep internal focus.",
        benefitTags: ["Control", "Deep Focus"],
        scienceBadge: "Traditional"
    )
    
    static let breath4_6 = BreathingPattern(
        title: "4-6 Breathing",
        inhale: 4, hold1: 0, exhale: 6, hold2: 0,
        icon: "lungs",
        colorHex: 0x5C7C8A,
        category: .calm,
        mascotMood: .calm,
        description: "Inhale for 4 seconds, exhale for 6 seconds for general relaxation.",
        scienceDetail: "A gentle prolongation of exhalation that mechanically shifts dominance towards the parasympathetic system (rest and digest).",
        benefitTags: ["Relaxation", "Simplicity"],
        scienceBadge: "General"
    )
    
    static let ratio1_2 = BreathingPattern(
        title: "1:2 Ratio",
        inhale: 4, hold1: 0, exhale: 8, hold2: 0,
        icon: "scale.3d",
        colorHex: 0x635D7A,
        category: .sleep,
        mascotMood: .sleepy,
        description: "Exhalation lasts exactly twice as long as inhalation.",
        scienceDetail: "Doubling expiratory duration maximizes parasympathetic activation and heart rate deceleration (respiratory sinus arrhythmia).",
        benefitTags: ["Recovery", "Heart Rate ↓"],
        scienceBadge: "Physiology"
    )
    
    static let triangleBottom = BreathingPattern(
        title: "Triangle (Bottom Base)",
        inhale: 4, hold1: 4, exhale: 4, hold2: 0,
        icon: "triangle.fill",
        colorHex: 0x7F9F80,
        category: .focus,
        mascotMood: .meditating,
        description: "Inhale, hold full, and exhale. No empty pause.",
        scienceDetail: "Gently energizes and improves concentration without the discomfort of breath retention with empty lungs.",
        benefitTags: ["Concentration", "Gentle Energy"],
        scienceBadge: "Technical"
    )
    
    static let triangleInverted = BreathingPattern(
        title: "Inverted Triangle",
        inhale: 4, hold1: 0, exhale: 4, hold2: 4,
        icon: "arrowtriangle.down.fill",
        colorHex: 0x635D7A,
        category: .calm,
        mascotMood: .calm,
        description: "Inhale, exhale, and hold with empty lungs.",
        scienceDetail: "Post-expiratory pause induces a profound decompression and muscular relaxation response by temporarily reducing thoracic volume.",
        benefitTags: ["Decompression", "Muscle Relaxation"],
        scienceBadge: "Technical"
    )
    
    static let pursedLips = BreathingPattern(
        title: "Pursed Lips",
        inhale: 2, hold1: 0, exhale: 4, hold2: 0,
        icon: "mouth",
        colorHex: 0xC88A8A,
        category: .calm,
        mascotMood: .supportive,
        description: "Inhale through nose, exhale through mouth with pursed lips.",
        scienceDetail: "Clinical technique for pulmonary recovery. Creates Positive Expiratory Pressure (PEEP), keeping airways open longer.",
        benefitTags: ["Pulmonary Recovery", "PEEP"],
        scienceBadge: "Clinical"
    )
    
    static let bhramari = BreathingPattern(
        title: "Bhramari (Bee Breath)",
        inhale: 4, hold1: 0, exhale: 8, hold2: 0,
        icon: "ear",
        colorHex: 0x8A8AC8,
        category: .anxiety,
        mascotMood: .meditating,
        description: "Cover ears and exhale producing a humming sound.",
        scienceDetail: "Prolonged humming stimulates vagal mechanoreceptors and fosters endogenous nitric oxide release for extreme calm.",
        benefitTags: ["Nitric Oxide", "Sensory Isolation"],
        scienceBadge: "Traditional"
    )
    
    static let sitali = BreathingPattern(
        title: "Sitali (Cooling)",
        inhale: 4, hold1: 0, exhale: 6, hold2: 0,
        icon: "thermometer.snowflake",
        colorHex: 0x5C7C8A,
        category: .calm,
        mascotMood: .calm,
        description: "Inhale through a rolled tongue, exhale through nose.",
        scienceDetail: "Air passing over the moist tongue creates an evaporative cooling effect, slightly lowering body temperature.",
        benefitTags: ["Cooling", "Temperature ↓"],
        scienceBadge: "Traditional"
    )
    
    static let sitkari = BreathingPattern(
        title: "Sitkari",
        inhale: 4, hold1: 0, exhale: 6, hold2: 0,
        icon: "mouth.fill",
        colorHex: 0x5C7C8A,
        category: .calm,
        mascotMood: .calm,
        description: "Inhale through closed teeth producing a hissing sound.",
        scienceDetail: "Cooling alternative to Sitali. Fosters facial muscle control and focus on thermal air flow sensations.",
        benefitTags: ["Sensory Focus", "Cooling"],
        scienceBadge: "Traditional"
    )
    
    static let breath3_6_9 = BreathingPattern(
        title: "3-6-9 Breathing",
        inhale: 3, hold1: 6, exhale: 9, hold2: 0,
        icon: "moon.zzz.fill",
        colorHex: 0x635D7A,
        category: .sleep,
        mascotMood: .sleepy,
        description: "Inhale 3s, hold 6s, exhale very slowly for 9s.",
        scienceDetail: "Extreme progression maximizing exhalation time to induce deep drowsiness and deactivate cortical alert circuits.",
        benefitTags: ["Drowsiness", "Natural Sedation"],
        scienceBadge: "Rest"
    )
    
    static let breath5_2_5 = BreathingPattern(
        title: "5-2-5 Breathing",
        inhale: 5, hold1: 2, exhale: 5, hold2: 0,
        icon: "brain.head.profile",
        colorHex: 0x7F9F80,
        category: .focus,
        mascotMood: .meditating,
        description: "Inhale 5s, brief relaxed pause of 2s, exhale 5s.",
        scienceDetail: "Modified coherence pattern with brief pauses maintaining a state of 'relaxed alertness' (Alpha State), ideal for working.",
        benefitTags: ["Relaxed Alertness", "Alpha Waves"],
        scienceBadge: "Productivity"
    )
    
    static let diaphragmatic = BreathingPattern(
        title: "Pure Diaphragmatic",
        inhale: 4, hold1: 0, exhale: 6, hold2: 0,
        icon: "figure.mind.and.body",
        colorHex: 0xD27D60,
        category: .calm,
        mascotMood: .breathing,
        description: "360-degree abdominal expansion without elevating shoulders.",
        scienceDetail: "Maximizes oxygen exchange in pulmonary bases and mechanically stabilizes the spine and pelvic core.",
        benefitTags: ["Core Stability", "Muscle Efficiency"],
        scienceBadge: "Biomechanics"
    )
    
    static let clavicular = BreathingPattern(
        title: "Clavicular",
        inhale: 2, hold1: 0, exhale: 2, hold2: 0,
        icon: "lungs.fill",
        colorHex: 0xD26060,
        category: .energy,
        mascotMood: .energetic,
        description: "Short breathing focused on elevating the clavicles.",
        scienceDetail: "Mechanically simulates acute stress pattern. Used therapeutically to induce mild hyperventilation and conscious sympathetic activation.",
        benefitTags: ["Sympathetic Activation", "Acute Stress"],
        scienceBadge: "Therapy"
    )
    
    static let suryaBhedana = BreathingPattern(
        title: "Surya Bhedana",
        inhale: 4, hold1: 0, exhale: 4, hold2: 0,
        icon: "sun.max.fill",
        colorHex: 0xD27D60,
        category: .energy,
        mascotMood: .energetic,
        description: "Inhale exclusively through right nostril, exhale through left.",
        scienceDetail: "Physiologically associated with left cerebral hemisphere activation. Induces core temperature increase and rapid cognitive alertness.",
        benefitTags: ["Cognitive Alertness", "Heat ↑"],
        scienceBadge: "Traditional"
    )
    
    static let chandraBhedana = BreathingPattern(
        title: "Chandra Bhedana",
        inhale: 4, hold1: 0, exhale: 4, hold2: 0,
        icon: "moon.fill",
        colorHex: 0x5C7C8A,
        category: .calm,
        mascotMood: .calm,
        description: "Inhale exclusively through left nostril, exhale through right.",
        scienceDetail: "Associated with right cerebral hemisphere activation. Fosters body temperature reduction and parasympathetic relaxation.",
        benefitTags: ["Right Relaxation", "Cold ↑"],
        scienceBadge: "Traditional"
    )
    
    static let runningCadence = BreathingPattern(
        title: "3:2 Running Cadence",
        inhale: 3, hold1: 0, exhale: 2, hold2: 0,
        icon: "figure.run",
        colorHex: 0x7F9F80,
        category: .focus,
        mascotMood: .energetic,
        description: "Asymmetric pattern to sync with running footfalls.",
        scienceDetail: "Inhale for 3 steps, exhale for 2. Alternates the initial impact foot upon exhaling, preventing unilateral mechanical injuries.",
        benefitTags: ["Aerobic Efficiency", "Injury Prevention"],
        scienceBadge: "Biomechanics"
    )
    
    static let lionsBreath = BreathingPattern(
        title: "Lion's Breath",
        inhale: 4, hold1: 0, exhale: 2, hold2: 0,
        icon: "mouth.fill",
        colorHex: 0xC88A8A,
        category: .anxiety,
        mascotMood: .energetic,
        description: "Inhale nose. Explosive mouth exhale extending tongue ('ha').",
        scienceDetail: "Fosters strong release of orofacial and jaw muscular tension (associated with chronic stress), improving local circulation.",
        benefitTags: ["Facial Tension ↓", "Catharsis"],
        scienceBadge: "Traditional"
    )
    
    static let holotropic = BreathingPattern(
        title: "Holotropic (Simulated)",
        inhale: 2.5, hold1: 0, exhale: 2.5, hold2: 0,
        icon: "sparkles",
        colorHex: 0x9A5C8A,
        category: .custom,
        mascotMood: .meditating,
        description: "Rapid, deep, and continuous connected breathing.",
        scienceDetail: "Induces altered states of consciousness via massive respiratory alkalosis and selective restriction of cerebral blood flow.",
        benefitTags: ["Alkalosis", "Emotional Catharsis"],
        scienceBadge: "Psychiatry"
    )
    
    static let apneaCO2 = BreathingPattern(
        title: "CO2 Apnea Tables",
        inhale: 4, hold1: 0, exhale: 4, hold2: 15,
        icon: "stopwatch.fill",
        colorHex: 0x4A7B76,
        category: .focus,
        mascotMood: .meditating,
        description: "Simulation: Constant recovery times with fixed breath holds.",
        scienceDetail: "Freediving training. Acclimates brainstem chemoreceptors to tolerate increasing levels of carbon dioxide without diaphragmatic spasms.",
        benefitTags: ["Hypercapnia Tolerance", "Diving"],
        scienceBadge: "Extreme Sports"
    )
    
    static let apneaO2 = BreathingPattern(
        title: "O2 Apnea Tables",
        inhale: 5, hold1: 0, exhale: 5, hold2: 30,
        icon: "timer",
        colorHex: 0x635D7A,
        category: .focus,
        mascotMood: .meditating,
        description: "Simulation: Increasing breath holds with recovery.",
        scienceDetail: "Adapts the body to function efficiently under mild hypoxia, inducing splenic release of additional red blood cells.",
        benefitTags: ["Hypoxia Tolerance", "Red Blood Cells"],
        scienceBadge: "Extreme Sports"
    )
    
    static let valsalva = BreathingPattern(
        title: "Valsalva Maneuver",
        inhale: 3, hold1: 3, exhale: 3, hold2: 0,
        icon: "figure.strengthtraining.traditional",
        colorHex: 0xD26060,
        category: .energy,
        mascotMood: .energetic,
        description: "Maximum inhalation, glottis closure, and abdominal bracing.",
        scienceDetail: "Creates massive intra-abdominal pressure acting as an internal 'lifting belt', rigidly stabilizing the spine during heavy lifts.",
        benefitTags: ["Brute Force", "Mechanical Stability"],
        scienceBadge: "Biomechanics"
    )
    
    static let allPresets: [BreathingPattern] = [
        boxBreathing, fourSevenEight, physiologicalSigh, coherentBreathing, wimHof, nadiShodhana, buteyko, kapalabhati, bhastrika, ujjayi, breath4_6, ratio1_2, triangleBottom, triangleInverted, pursedLips, bhramari, sitali, sitkari, breath3_6_9, breath5_2_5, diaphragmatic, clavicular, suryaBhedana, chandraBhedana, runningCadence, lionsBreath, holotropic, apneaCO2, apneaO2, valsalva
    ]
    
    static func presetsFor(mood: MoodState) -> [BreathingPattern] {
        switch mood {
        case .calm:          return [coherentBreathing, breath4_6, sitali, buteyko, pursedLips, chandraBhedana, triangleInverted]
        case .focus:         return [boxBreathing, ujjayi, breath5_2_5, apneaCO2, apneaO2, runningCadence, triangleBottom]
        case .sleep:         return [fourSevenEight, ratio1_2, breath3_6_9]
        case .energy:        return [kapalabhati, bhastrika, wimHof, suryaBhedana, clavicular, valsalva]
        case .anxietyRelief: return [physiologicalSigh, nadiShodhana, bhramari, lionsBreath, sitkari, diaphragmatic]
        }
    }
}