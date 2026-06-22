import UIKit
import CoreHaptics

// MARK: - Haptics Manager

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    // MARK: - UIKit Feedback Generators (for discrete UI events)
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - CoreHaptics Engine (for continuous breathing haptics)
    
    private var hapticEngine: CHHapticEngine?
    private var breathingPlayer: CHHapticAdvancedPatternPlayer?
    private var supportsHaptics: Bool = false
    
    // MARK: - Init
    
    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareUIKitGenerators()
        createHapticEngine()
    }
    
    // MARK: - UIKit Generator Preparation
    
    private func prepareUIKitGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - CoreHaptics Engine Setup
    
    private func createHapticEngine() {
        guard supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            
            // Auto-restart if the engine stops (e.g., app goes to background and returns)
            hapticEngine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }
            
            // Reset handler — called when the engine needs to recover
            hapticEngine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }
            
            try hapticEngine?.start()
        } catch {
            supportsHaptics = false
        }
    }
    
    private func restartEngine() {
        guard supportsHaptics else { return }
        do {
            try hapticEngine?.start()
        } catch {
            supportsHaptics = false
        }
    }
    
    // MARK: - Continuous Breathing Haptics
    
    /// Plays a continuous haptic pattern synchronized to a breathing phase.
    /// - Parameters:
    ///   - phase: The current breathing phase (inhale, hold, exhale, hold2)
    ///   - duration: The duration of the phase in seconds
    func playBreathingHaptic(phase: BreathPhase, duration: TimeInterval) {
        guard supportsHaptics, let engine = hapticEngine else { return }
        
        // Stop any existing breathing player first
        stopBreathingHaptic()
        
        do {
            let pattern = try buildBreathingPattern(phase: phase, duration: duration)
            breathingPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
            // Auto-cleanup when the player finishes
            breathingPlayer?.completionHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.breathingPlayer = nil
                }
            }
            
            try breathingPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Graceful fallback — use the old discrete haptic
            phaseTransition(phase)
        }
    }
    
    /// Immediately stops continuous breathing haptics (called on Pause or End Session).
    func stopBreathingHaptic() {
        do {
            try breathingPlayer?.stop(atTime: CHHapticTimeImmediate)
        } catch {
            // Silently ignore — player may already be stopped
        }
        breathingPlayer = nil
    }
    
    // MARK: - Breathing Pattern Builders
    
    private func buildBreathingPattern(phase: BreathPhase, duration: TimeInterval) throws -> CHHapticPattern {
        switch phase {
        case .inhale:
            return try buildInhalePattern(duration: duration)
        case .exhale:
            return try buildExhalePattern(duration: duration)
        case .hold1:
            return try buildHoldPattern(duration: duration, intensity: 0.45)
        case .hold2:
            return try buildHoldPattern(duration: duration, intensity: 0.15)
        }
    }
    
    /// Inhale: Intensity ramps smoothly from 0.1 → 0.7, sharpness from 0.1 → 0.5
    /// Creates a "gathering energy" sensation.
    private func buildInhalePattern(duration: TimeInterval) throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: duration
        )
        
        // Smooth intensity ramp up
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.15),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.2, value: 0.25),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.45),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.8, value: 0.6),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.7)
            ],
            relativeTime: 0
        )
        
        // Gentle sharpness rise
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.1),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.3),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.5)
            ],
            relativeTime: 0
        )
        
        return try CHHapticPattern(events: [event], parameterCurves: [intensityCurve, sharpnessCurve])
    }
    
    /// Exhale: Intensity ramps smoothly from 0.6 → 0.05, sharpness from 0.4 → 0.05
    /// Creates a "releasing energy" sensation.
    private func buildExhalePattern(duration: TimeInterval) throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            ],
            relativeTime: 0,
            duration: duration
        )
        
        // Smooth intensity ramp down
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.6),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.2, value: 0.45),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.25),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.8, value: 0.12),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.05)
            ],
            relativeTime: 0
        )
        
        // Gentle sharpness fade
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.4),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: 0.2),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0.05)
            ],
            relativeTime: 0
        )
        
        return try CHHapticPattern(events: [event], parameterCurves: [intensityCurve, sharpnessCurve])
    }
    
    /// Hold: A subtle, steady vibration at a constant intensity.
    /// hold1 (after inhale) is at higher intensity, hold2 (after exhale) is barely perceptible.
    private func buildHoldPattern(duration: TimeInterval, intensity: Float) throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ],
            relativeTime: 0,
            duration: duration
        )
        
        // Very gentle pulse — slight oscillation to keep it alive but not distracting
        let pulseCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: intensity),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.25, value: intensity * 0.8),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.5, value: intensity),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.75, value: intensity * 0.8),
                CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: intensity)
            ],
            relativeTime: 0
        )
        
        return try CHHapticPattern(events: [event], parameterCurves: [pulseCurve])
    }
    
    // MARK: - Session Lifecycle Haptics
    
    /// A satisfying "thud" when the user starts a breathing session.
    func sessionStart() {
        guard supportsHaptics, let engine = hapticEngine else {
            impactHeavy.impactOccurred(intensity: 0.7)
            impactHeavy.prepare()
            return
        }
        
        do {
            // A quick transient "bloom" — two transient taps with rising intensity
            let tap1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
            let tap2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.08
            )
            // Brief continuous bloom
            let bloom = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.1,
                duration: 0.3
            )
            let fadeOut = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.6),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.4, value: 0.0)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [tap1, tap2, bloom], parameterCurves: [fadeOut])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            impactHeavy.impactOccurred(intensity: 0.7)
            impactHeavy.prepare()
        }
    }
    
    /// A satisfying "success" haptic when the session completes — triple pulse crescendo.
    func sessionComplete() {
        guard supportsHaptics, let engine = hapticEngine else {
            notificationFeedback.notificationOccurred(.success)
            notificationFeedback.prepare()
            return
        }
        
        do {
            let tap1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
            let tap2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.12
            )
            let tap3 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.24
            )
            // Final warm glow
            let glow = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                ],
                relativeTime: 0.3,
                duration: 0.5
            )
            let glowFade = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.3, value: 0.5),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.8, value: 0.0)
                ],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [tap1, tap2, tap3, glow], parameterCurves: [glowFade])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            notificationFeedback.notificationOccurred(.success)
            notificationFeedback.prepare()
        }
    }
    
    // MARK: - Discrete UI Haptics (unchanged)
    
    /// Legacy phase transition — used as fallback if CoreHaptics is unavailable.
    func phaseTransition(_ phase: BreathPhase) {
        switch phase {
        case .inhale:
            impactMedium.impactOccurred(intensity: 0.6)
        case .hold1, .hold2:
            impactLight.impactOccurred(intensity: 0.3)
        case .exhale:
            impactMedium.impactOccurred(intensity: 0.5)
        }
        impactLight.prepare()
        impactMedium.prepare()
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }
    
    func tap() {
        impactLight.impactOccurred(intensity: 0.5)
        impactLight.prepare()
    }
    
    func milestone() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }
}
