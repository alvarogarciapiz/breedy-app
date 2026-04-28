import SwiftUI
import Observation

// MARK: - Breathing Engine State Machine

enum BreathingEngineState: Equatable {
    case idle
    case active
    case paused
    case completed
}

@Observable
@MainActor
final class BreathingEngine {
    
    // MARK: - Published State
    
    private(set) var state: BreathingEngineState = .idle
    private(set) var currentPhase: BreathPhase = .inhale
    private(set) var phaseTimeRemaining: Double = 0
    private(set) var phaseDuration: Double = 0
    private(set) var totalTimeRemaining: Double = 0
    private(set) var totalDuration: Double = 0
    private(set) var completedCycles: Int = 0
    private(set) var elapsedSeconds: Double = 0
    private(set) var phaseProgress: Double = 0  // 0...1 within current phase
    private(set) var orbScale: CGFloat = 0.6
    private(set) var isTransitioning: Bool = false
    
    // MARK: - Configuration
    
    private(set) var pattern: BreathingPattern?
    private(set) var durationMode: SessionDurationMode = .timed(seconds: 300)
    
    // MARK: - Internals
    
    private var timer: Timer?
    private var phaseIndex: Int = 0
    private var phases: [(BreathPhase, Double)] = []
    private var targetCycles: Int?
    private let tickInterval: TimeInterval = 0.05  // 50ms for smooth animation
    
    // Callbacks
    var onPhaseChange: ((BreathPhase) -> Void)?
    var onCycleComplete: (() -> Void)?
    var onSessionComplete: (() -> Void)?
    
    // MARK: - Lifecycle
    
    func configure(pattern: BreathingPattern, durationMode: SessionDurationMode) {
        self.pattern = pattern
        self.durationMode = durationMode
        self.phases = pattern.phases
        
        switch durationMode {
        case .timed(let seconds):
            totalDuration = Double(seconds)
            targetCycles = nil
        case .cycles(let count):
            totalDuration = pattern.cycleDuration * Double(count)
            targetCycles = count
        }
        
        reset()
    }
    
    func start() {
        guard state == .idle || state == .paused else { return }
        
        if state == .idle {
            reset()
            totalTimeRemaining = totalDuration
            setPhase(index: 0)
        }
        
        state = .active
        startTimer()
    }
    
    func pause() {
        guard state == .active else { return }
        state = .paused
        stopTimer()
    }
    
    func resume() {
        guard state == .paused else { return }
        state = .active
        startTimer()
    }
    
    func stop() {
        stopTimer()
        state = .completed
        onSessionComplete?()
    }
    
    func reset() {
        stopTimer()
        state = .idle
        phaseIndex = 0
        completedCycles = 0
        elapsedSeconds = 0
        phaseProgress = 0
        totalTimeRemaining = totalDuration
        orbScale = 0.6
        isTransitioning = false
        
        if !phases.isEmpty {
            currentPhase = phases[0].0
            phaseDuration = phases[0].1
            phaseTimeRemaining = phases[0].1
        }
    }
    
    // MARK: - Timer Logic
    
    private func startTimer() {
        let interval = tickInterval
        let timer = Timer(timeInterval: interval, repeats: true) { @Sendable [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        guard state == .active else { return }
        
        elapsedSeconds += tickInterval
        totalTimeRemaining -= tickInterval
        phaseTimeRemaining -= tickInterval
        
        // Update phase progress
        if phaseDuration > 0 {
            phaseProgress = 1.0 - (phaseTimeRemaining / phaseDuration)
        }
        
        // Update orb scale smoothly
        updateOrbScale()
        
        // Check if phase is complete
        if phaseTimeRemaining <= 0 {
            advancePhase()
        }
        
        // Check session completion
        if totalTimeRemaining <= 0 {
            stop()
            return
        }
        
        if let target = targetCycles, completedCycles >= target {
            stop()
        }
    }
    
    private func advancePhase() {
        phaseIndex += 1
        
        if phaseIndex >= phases.count {
            // Cycle complete
            phaseIndex = 0
            completedCycles += 1
            onCycleComplete?()
        }
        
        setPhase(index: phaseIndex)
    }
    
    private func setPhase(index: Int) {
        guard index < phases.count else { return }
        
        isTransitioning = true
        
        let (phase, duration) = phases[index]
        currentPhase = phase
        phaseDuration = duration
        phaseTimeRemaining = duration
        phaseProgress = 0
        
        onPhaseChange?(phase)
        
        // Brief transition state
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            self.isTransitioning = false
        }
    }
    
    private func updateOrbScale() {
        let target = currentPhase.orbScale
        let current = orbScale
        let speed: CGFloat = CGFloat(tickInterval) * 2.0
        
        if abs(target - current) > 0.001 {
            orbScale += (target - current) * speed
        }
    }
    
    // MARK: - Computed
    
    var formattedTimeRemaining: String {
        let minutes = Int(totalTimeRemaining) / 60
        let seconds = Int(totalTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedPhaseTime: String {
        let seconds = max(0, Int(ceil(phaseTimeRemaining)))
        return "\(seconds)"
    }
    
    var sessionProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return elapsedSeconds / totalDuration
    }
}
