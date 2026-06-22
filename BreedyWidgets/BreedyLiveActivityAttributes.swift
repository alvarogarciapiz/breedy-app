import ActivityKit
import Foundation

// MARK: - Live Activity Attributes

/// Shared between the main app and the BreedyWidgets extension.
/// Defines the static and dynamic data for a breathing session Live Activity.
struct BreedySessionAttributes: ActivityAttributes {
    
    // MARK: - Static Data (set once when the activity starts)
    
    /// The name of the breathing pattern (e.g., "Box Breathing")
    let patternName: String
    
    /// The hex color of the pattern's accent for theming the widget
    let patternColorHex: UInt
    
    // MARK: - Dynamic Content State (updated on every phase change)
    
    struct ContentState: Codable, Hashable {
        /// Display name of the current phase (e.g., "Inhale", "Hold", "Exhale")
        let phaseName: String
        
        /// SF Symbol name for the current phase
        let phaseIcon: String
        
        /// The date when the current phase ends — used with `Text(.timerInterval)` for live countdown
        let phaseEndDate: Date
        
        /// The date when the entire session ends
        let totalEndDate: Date
        
        /// Number of completed breathing cycles
        let completedCycles: Int
        
        /// Whether the session is currently paused
        let isPaused: Bool
    }
}
