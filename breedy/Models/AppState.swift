import SwiftUI
import Observation

// MARK: - App State

@Observable
@MainActor
final class AppState {
    
    // Navigation
    var selectedTab: AppTab = .home
    var showOnboarding: Bool = false
    var showSession: Bool = false
    
    // Session Configuration
    var activePattern: BreathingPattern?
    var activeMood: MoodState?
    
    // Onboarding state
    @ObservationIgnored
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @ObservationIgnored
    @AppStorage("userGoal") var userGoal: String = ""
    @ObservationIgnored
    @AppStorage("mascotEnabled") var mascotEnabled = true
    @ObservationIgnored
    @AppStorage("mascotIntensity") var mascotIntensity: String = "normal"
    
    // Settings
    @ObservationIgnored
    @AppStorage("soundEnabled") var soundEnabled = true
    @ObservationIgnored
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @ObservationIgnored
    @AppStorage("voiceCuesEnabled") var voiceCuesEnabled = false
    @ObservationIgnored
    @AppStorage("selectedTheme") var selectedTheme: String = "system"
    @ObservationIgnored
    @AppStorage("privacyMode") var privacyMode = false
    
    // Time-based greeting
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }
    
    var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "☀️"
        case 12..<17: return "🌤️"
        case 17..<21: return "🌅"
        default:      return "🌙"
        }
    }
    
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }
    
    // MARK: - Actions
    
    func startSession(pattern: BreathingPattern, mood: MoodState? = nil) {
        activePattern = pattern
        activeMood = mood
        showSession = true
    }
    
    func endSession() {
        showSession = false
        activePattern = nil
    }
    
    var colorSchemeOverride: ColorScheme? {
        switch selectedTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable {
    case home = "Home"
    case sessions = "Sessions"
    case progress = "Progress"
    case companion = "Companion"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .sessions:  return "wind"
        case .progress:  return "chart.bar.fill"
        case .companion: return "face.smiling.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - Time of Day

enum TimeOfDay {
    case morning, afternoon, evening, night
    
    var gradientColors: [Color] {
        switch self {
        case .morning:   return [Color(hex: 0xFFF8E1), Color(hex: 0xFFECB3)]
        case .afternoon: return [Color(hex: 0xE3F2FD), Color(hex: 0xBBDEFB)]
        case .evening:   return [Color(hex: 0xFCE4EC), Color(hex: 0xF8BBD0)]
        case .night:     return [Color(hex: 0x1A1A2E), Color(hex: 0x16213E)]
        }
    }
    
    var mascotMood: MascotMood {
        switch self {
        case .morning:   return .energetic
        case .afternoon: return .calm
        case .evening:   return .calm
        case .night:     return .sleepy
        }
    }
}
