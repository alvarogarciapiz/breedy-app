import UIKit

// MARK: - Haptics Manager

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
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
    
    func sessionStart() {
        impactHeavy.impactOccurred(intensity: 0.7)
        impactHeavy.prepare()
    }
    
    func sessionComplete() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
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
