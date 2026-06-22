import SwiftUI
import ActivityKit

// MARK: - Breathing Session View

struct BreathingSessionView: View {
    let pattern: BreathingPattern
    let mood: MoodState?
    let onComplete: (Int, Int, Bool) -> Void  // duration, cycles, completed
    let onDismiss: () -> Void
    
    @State private var engine = BreathingEngine()
    @State private var showUI = true
    @State private var zenMode = false
    @State private var selectedDuration: Int = 300
    @State private var hasStarted = false
    @State private var orbIsBreathing = false
    @State private var showCompletion = false
    @State private var showConfetti = false
    @State private var postSessionFeeling: Int = 0  // 0 = not selected, 1-5 = feeling
    @State private var bgRotation: Double = 0
    @State private var liveActivity: Activity<BreedySessionAttributes>?
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ALWAYS in hierarchy to ensure smooth initial animation
                activeSessionView(geometry: geometry)
                    .opacity(hasStarted && !showCompletion ? 1 : 0)
                    .allowsHitTesting(hasStarted && !showCompletion)
                
                if !hasStarted {
                    preSessionView(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if showCompletion {
                    completionView(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background {
                backgroundGradient
                    .ignoresSafeArea()
            }
        }
        .statusBarHidden(zenMode && hasStarted)
        .onAppear { configureEngine() }
        .onDisappear { engine.stop() }
        .onChange(of: engine.state) { _, newState in
            if newState == .completed {
                handleSessionComplete()
            }
        }
    }
    
    // MARK: - Pre-Session
    
    private func preSessionView(geometry: GeometryProxy) -> some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            // Close button
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, BDDesign.Spacing.md)
            
            Spacer()
            
            // Ultra-minimalist Pattern info
            VStack(spacing: BDDesign.Spacing.lg) {
                // Mascot
                BreedyImageView(
                    imageName: "breedy_breathe",
                    size: 100,
                    auraColor: pattern.accentColor.opacity(0.3)
                )
                .padding(.bottom, BDDesign.Spacing.sm)
                
                Text(pattern.title)
                    .font(BDDesign.Typography.displayHero)
                    .tracking(-1.5)
                    .foregroundStyle(.white)
                
                Text(patternTimingString)
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Glassmorphic Duration picker
            VStack(spacing: BDDesign.Spacing.md) {
                Text("Select Duration")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(.white.opacity(0.5))
                
                HStack(spacing: BDDesign.Spacing.sm) {
                    ForEach([60, 180, 300, 600], id: \.self) { seconds in
                        durationButton(seconds: seconds)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.bottom, BDDesign.Spacing.md)
            
            // Start button
            Button {
                HapticsManager.shared.sessionStart()
                withAnimation(BDDesign.Motion.standard) {
                    hasStarted = true
                }
                engine.start()
                UIApplication.shared.isIdleTimerDisabled = true
                startLiveActivity()
                
                // Decouple the breathing scale animation from the view transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    orbIsBreathing = true
                }
            } label: {
                Text("Begin")
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: BDDesign.Radius.pill)
                            .fill(.white)
                            .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                    )
            }
            .padding(.horizontal, BDDesign.Spacing.xl)
            .padding(.bottom, BDDesign.Spacing.xxl)
        }
    }
    
    // MARK: - Active Session
    
    private func activeSessionView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Tap to toggle UI
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(BDDesign.Motion.quick) {
                        showUI.toggle()
                    }
                }
            
            // 1. Absolutely Centered Breathing Area
            VStack(spacing: 80) {
                // Floating Instruction
                if showUI {
                    Text(engine.currentPhase.instruction)
                        .font(.system(size: 42, weight: .regular, design: .default))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .animation(.easeInOut, value: engine.currentPhase)
                } else {
                    Text(" ")
                        .font(.system(size: 42, weight: .regular, design: .default))
                }
                
                // Breathing orb
                ZStack {
                    BreathingOrbView(
                        phase: engine.currentPhase,
                        progress: engine.phaseProgress,
                        phaseDuration: engine.phaseDuration,
                        accentColor: pattern.accentColor,
                        size: min(geometry.size.width * 0.75, 340),
                        isActive: orbIsBreathing
                    )
                    
                    // Countdown in center
                    Text(engine.formattedPhaseTime)
                        .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(engine.currentPhase == .hold1 || engine.currentPhase == .hold2 ? 0.4 : 0.9)
                        .animation(.easeInOut, value: engine.currentPhase)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. UI Overlays (Top and Bottom Docks)
            VStack(spacing: 0) {
                if showUI && !zenMode {
                    sessionTopBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                if showUI {
                    sessionBottomDock
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var sessionTopBar: some View {
        HStack {
            Button {
                engine.stop()
                UIApplication.shared.isIdleTimerDisabled = false
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
            
            Spacer()
            
            // Remaining time exactly centered
            Text(engine.formattedTimeRemaining)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                .contentTransition(.numericText())
            
            Spacer()
            
            // Zen mode
            Button {
                withAnimation(BDDesign.Motion.standard) {
                    zenMode.toggle()
                }
            } label: {
                Image(systemName: zenMode ? "eye.fill" : "eye.slash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
        }
        .padding(.horizontal, BDDesign.Spacing.xl)
        .padding(.top, BDDesign.Spacing.md)
    }
    
    // MARK: - Session Bottom Dock
    
    private var sessionBottomDock: some View {
        HStack {
                // End Session
                Button {
                    orbIsBreathing = false
                    if hapticsEnabled { HapticsManager.shared.stopBreathingHaptic() }
                    endLiveActivity()
                    engine.stop()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("End")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                }
                
                Spacer()
                
                // Play/Pause
                Button {
                    if engine.state == .active {
                        engine.pause()
                        if hapticsEnabled { HapticsManager.shared.stopBreathingHaptic() }
                        updateLiveActivity(isPaused: true)
                    } else {
                        engine.resume()
                        if hapticsEnabled {
                            HapticsManager.shared.playBreathingHaptic(
                                phase: engine.currentPhase,
                                duration: engine.phaseTimeRemaining
                            )
                        }
                        updateLiveActivityForResume()
                    }
                    if hapticsEnabled { HapticsManager.shared.tap() }
                } label: {
                    Image(systemName: engine.state == .active ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                
                Spacer()
                
                // Cycles count
                HStack(spacing: 6) {
                    Text("\(engine.completedCycles)")
                        .font(.system(size: 14, weight: .bold))
                    Text("cycles")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.6)
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
        .padding(.horizontal, BDDesign.Spacing.xl)
        .padding(.bottom, BDDesign.Spacing.xl)
    }
    
    // MARK: - Completion View
    
    private func completionView(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: BDDesign.Spacing.xl) {
                Spacer(minLength: BDDesign.Spacing.xl)
                
                let mascotName = pattern.category == .sleep ? "breedy_happy_sleep" : "breedy_greet"
                let mascotAura = pattern.category == .sleep ? BDDesign.Colors.accentSleep : Color(hex: 0xFFD700)
                BreedyImageView(imageName: mascotName, size: 120, auraColor: mascotAura)
                
                VStack(spacing: BDDesign.Spacing.sm) {
                    Text("Session Complete")
                        .font(BDDesign.Typography.displayHero)
                        .tracking(-1.5)
                        .foregroundStyle(.white)
                    
                    Text("You completed \(engine.completedCycles) cycles in \(formattedElapsed)")
                        .font(BDDesign.Typography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                
                // Stats
                HStack(spacing: BDDesign.Spacing.lg) {
                    completionStat(value: formattedElapsed, label: "Duration")
                    completionStat(value: "\(engine.completedCycles)", label: "Cycles")
                    completionStat(value: "+\(calculateXP()) XP", label: "Earned")
                }
                .padding(.horizontal)
                
                // Post-session reflection
                postSessionReflection
                
                // Science insight
                postSessionScienceInsight
                
                Button {
                    UIApplication.shared.isIdleTimerDisabled = false
                    let duration = Int(engine.elapsedSeconds)
                    let cycles = engine.completedCycles
                    onComplete(duration, cycles, true)
                    onDismiss()
                } label: {
                    Text("Finish")
                        .font(BDDesign.Typography.bodyMedium)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: BDDesign.Radius.pill)
                                .fill(.white)
                                .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                        )
                }
                .padding(.horizontal, BDDesign.Spacing.xl)
                .padding(.bottom, BDDesign.Spacing.xl)
            }
        }
    }
    
    // MARK: - Post-Session Reflection
    
    private var postSessionReflection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            Text("How do you feel now?")
                .font(BDDesign.Typography.bodyMedium)
                .foregroundStyle(.white.opacity(0.7))
            
            HStack(spacing: BDDesign.Spacing.md) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(BDDesign.Motion.quick) {
                            postSessionFeeling = level
                        }
                        HapticsManager.shared.selection()
                    } label: {
                        VStack(spacing: 4) {
                            Text(feelingEmoji(level))
                                .font(.system(size: postSessionFeeling == level ? 32 : 24))
                            Text(feelingLabel(level))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(postSessionFeeling == level ? 0.9 : 0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                                .fill(.white.opacity(postSessionFeeling == level ? 0.15 : 0.05))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, BDDesign.Spacing.xl)
    }
    
    private var postSessionScienceInsight: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(pattern.accentColor)
                Text("What just happened")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Text(postSessionScienceText)
                .font(BDDesign.Typography.bodySmall)
                .foregroundStyle(.white.opacity(0.5))
                .lineSpacing(3)
            
            // Estimated impact pills
            HStack(spacing: 8) {
                ForEach(pattern.benefitTags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(pattern.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pattern.accentColor.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(BDDesign.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                .fill(.white.opacity(0.06))
        }
        .padding(.horizontal, BDDesign.Spacing.xl)
    }
    
    private var postSessionScienceText: String {
        let cycles = engine.completedCycles
        let minutes = Int(engine.elapsedSeconds) / 60
        
        switch pattern.category {
        case .calm:
            return "Your vagus nerve received \(cycles) cycles of stimulation. This activates your parasympathetic nervous system, lowering heart rate and promoting deep calm."
        case .focus:
            return "\(minutes) minutes of structured breathing increased alpha brain wave activity. Your prefrontal cortex is now primed for focused, clear thinking."
        case .sleep:
            return "The extended exhale pattern activated your body's sleep preparation response. Core body temperature is dropping and melatonin production is increasing."
        case .energy:
            return "Fast-paced rhythmic breathing released noradrenaline, your body's natural alertness chemical. You should feel more awake and energized."
        case .anxiety:
            return "Your \(cycles) breathing cycles directly stimulated the vagal brake, counteracting the fight-or-flight response. Cortisol levels are estimated to have dropped ~15%."
        case .custom:
            return "You completed \(cycles) controlled breathing cycles. Each cycle helps regulate your autonomic nervous system and build stress resilience over time."
        }
    }
    
    private func feelingEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😣"
        case 2: return "😕"
        case 3: return "😌"
        case 4: return "😊"
        case 5: return "🤩"
        default: return "😐"
        }
    }
    
    private func feelingLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Worse"
        case 2: return "Same"
        case 3: return "Calm"
        case 4: return "Better"
        case 5: return "Amazing"
        default: return ""
        }
    }
    
    private func completionStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BDDesign.Typography.cardTitle)
                .foregroundStyle(.white)
            Text(label)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color(hex: 0x050505).ignoresSafeArea()
            
            // Dynamic blurred glowing orbs
            ZStack {
                Circle()
                    .fill(pattern.accentColor.opacity(0.3))
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .offset(x: -80, y: -150)
                    
                Circle()
                    .fill(pattern.accentColor.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: 150, y: 200)
            }
            .rotationEffect(.degrees(bgRotation))
            .onAppear {
                withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
                    bgRotation = 360
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    // MARK: - Duration Button
    
    private func durationButton(seconds: Int) -> some View {
        let label: String = switch seconds {
        case 60: "1 min"
        case 180: "3 min"
        case 300: "5 min"
        case 600: "10 min"
        default: "\(seconds / 60) min"
        }
        
        return Button {
            selectedDuration = seconds
            engine.configure(
                pattern: pattern,
                durationMode: .timed(seconds: seconds)
            )
            if hapticsEnabled { HapticsManager.shared.selection() }
        } label: {
            Text(label)
                .font(BDDesign.Typography.button)
                .foregroundStyle(selectedDuration == seconds ? .black : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    if selectedDuration == seconds {
                        Capsule().fill(.white)
                    } else {
                        Capsule().fill(.clear)
                    }
                }
        }
    }
    
    // MARK: - Helpers
    
    private func configureEngine() {
        engine.configure(pattern: pattern, durationMode: .timed(seconds: selectedDuration))
        
        engine.onPhaseChange = { phase, duration in
            if hapticsEnabled {
                HapticsManager.shared.playBreathingHaptic(phase: phase, duration: duration)
            }
            updateLiveActivityPhase(phase: phase, duration: duration)
        }
        
        engine.onSessionComplete = {
            if hapticsEnabled {
                HapticsManager.shared.stopBreathingHaptic()
                HapticsManager.shared.sessionComplete()
            }
            endLiveActivity()
        }
    }
    
    private func handleSessionComplete() {
        withAnimation(BDDesign.Motion.slow) {
            showCompletion = true
            showConfetti = true
        }
        
        // Remove confetti after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfetti = false
        }
    }
    
    private var formattedElapsed: String {
        let minutes = Int(engine.elapsedSeconds) / 60
        let seconds = Int(engine.elapsedSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var patternTimingString: String {
        let parts = [
            "\(Int(pattern.inhaleSeconds))s in",
            pattern.hold1Seconds > 0 ? "\(Int(pattern.hold1Seconds))s hold" : nil,
            "\(Int(pattern.exhaleSeconds))s out",
            pattern.hold2Seconds > 0 ? "\(Int(pattern.hold2Seconds))s hold" : nil
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }
    
    private func calculateXP() -> Int {
        let minutes = Int(engine.elapsedSeconds) / 60
        return max(10, minutes * 10 + 20)
    }
    
    // MARK: - Live Activity Management
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = BreedySessionAttributes(
            patternName: pattern.title,
            patternColorHex: pattern.colorHex
        )
        
        let firstPhase = engine.currentPhase
        let initialState = BreedySessionAttributes.ContentState(
            phaseName: firstPhase.displayName,
            phaseIcon: firstPhase.icon,
            phaseEndDate: Date().addingTimeInterval(engine.phaseDuration),
            totalEndDate: Date().addingTimeInterval(engine.totalTimeRemaining),
            completedCycles: 0,
            isPaused: false
        )
        
        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Silently fail — Live Activity is a nice-to-have, not critical
        }
    }
    
    private func updateLiveActivityPhase(phase: BreathPhase, duration: TimeInterval) {
        guard let activity = liveActivity else { return }
        
        let state = BreedySessionAttributes.ContentState(
            phaseName: phase.displayName,
            phaseIcon: phase.icon,
            phaseEndDate: Date().addingTimeInterval(duration),
            totalEndDate: Date().addingTimeInterval(engine.totalTimeRemaining),
            completedCycles: engine.completedCycles,
            isPaused: false
        )
        
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }
    
    private func updateLiveActivity(isPaused: Bool) {
        guard let activity = liveActivity else { return }
        
        let state = BreedySessionAttributes.ContentState(
            phaseName: engine.currentPhase.displayName,
            phaseIcon: engine.currentPhase.icon,
            phaseEndDate: Date().addingTimeInterval(engine.phaseTimeRemaining),
            totalEndDate: Date().addingTimeInterval(engine.totalTimeRemaining),
            completedCycles: engine.completedCycles,
            isPaused: isPaused
        )
        
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }
    
    private func updateLiveActivityForResume() {
        guard let activity = liveActivity else { return }
        
        let state = BreedySessionAttributes.ContentState(
            phaseName: engine.currentPhase.displayName,
            phaseIcon: engine.currentPhase.icon,
            phaseEndDate: Date().addingTimeInterval(engine.phaseTimeRemaining),
            totalEndDate: Date().addingTimeInterval(engine.totalTimeRemaining),
            completedCycles: engine.completedCycles,
            isPaused: false
        )
        
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }
    
    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        
        let finalState = BreedySessionAttributes.ContentState(
            phaseName: "Complete",
            phaseIcon: "checkmark.circle.fill",
            phaseEndDate: Date(),
            totalEndDate: Date(),
            completedCycles: engine.completedCycles,
            isPaused: false
        )
        
        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + 5)
            )
        }
        liveActivity = nil
    }
}

#Preview {
    BreathingSessionView(
        pattern: BreathingPresets.boxBreathing,
        mood: .focus,
        onComplete: { _, _, _ in },
        onDismiss: {}
    )
}
