import SwiftUI

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
    @State private var showCompletion = false
    @State private var showConfetti = false
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()
                
                if !hasStarted {
                    preSessionView(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if showCompletion {
                    completionView(geometry: geometry)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    activeSessionView(geometry: geometry)
                        .transition(.opacity)
                }
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
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
            
            Spacer()
            
            // Pattern info
            VStack(spacing: BDDesign.Spacing.md) {
                Image(systemName: pattern.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(pattern.accentColor)
                
                Text(pattern.title)
                    .font(BDDesign.Typography.sectionHeading)
                    .tracking(-1.28)
                    .foregroundStyle(.white)
                
                Text(patternTimingString)
                    .font(BDDesign.Typography.monoCaption)
                    .foregroundStyle(.white.opacity(0.6))
                
                if let mood = mood {
                    Text(mood.greeting)
                        .font(BDDesign.Typography.bodySmall)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // Mascot
            BreedyMascotView(
                mood: pattern.mascotMood,
                size: 100
            )
            
            Spacer()
            
            // Duration picker
            VStack(spacing: BDDesign.Spacing.sm) {
                Text("Duration")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(.white.opacity(0.6))
                
                HStack(spacing: BDDesign.Spacing.sm) {
                    ForEach([60, 180, 300, 600], id: \.self) { seconds in
                        durationButton(seconds: seconds)
                    }
                }
            }
            
            // Start button
            Button {
                HapticsManager.shared.sessionStart()
                withAnimation(BDDesign.Motion.standard) {
                    hasStarted = true
                }
                engine.start()
                UIApplication.shared.isIdleTimerDisabled = true
            } label: {
                Text("Begin")
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(pattern.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable))
            }
            .padding(.horizontal, BDDesign.Spacing.xl)
            .padding(.bottom, BDDesign.Spacing.xl)
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
            
            VStack(spacing: 0) {
                if showUI && !zenMode {
                    // Top bar
                    sessionTopBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Central breathing area
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Phase indicator
                    VStack(spacing: BDDesign.Spacing.sm) {
                        Text(engine.currentPhase.displayName)
                            .font(BDDesign.Typography.breathPhase)
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        
                        if showUI {
                            Text(engine.currentPhase.instruction)
                                .font(BDDesign.Typography.bodySmall)
                                .foregroundStyle(.white.opacity(0.5))
                                .transition(.opacity)
                        }
                    }
                    
                    // Breathing orb
                    ZStack {
                        BreathingOrbView(
                            phase: engine.currentPhase,
                            progress: engine.phaseProgress,
                            accentColor: pattern.accentColor,
                            size: min(geometry.size.width * 0.6, 280)
                        )
                        
                        // Countdown in center
                        Text(engine.formattedPhaseTime)
                            .font(BDDesign.Typography.breathCountdown)
                            .foregroundStyle(.white.opacity(0.8))
                            .contentTransition(.numericText())
                    }
                    
                    // Mascot breathing with user
                    if showUI && !zenMode {
                        BreedyMascotView(
                            mood: .breathing,
                            size: 56,
                            isBreathing: true,
                            breathScale: engine.currentPhase.orbScale
                        )
                        .transition(.opacity)
                    }
                }
                
                Spacer()
                
                if showUI {
                    // Bottom controls
                    sessionBottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Session Top Bar
    
    private var sessionTopBar: some View {
        HStack {
            Button {
                engine.stop()
                UIApplication.shared.isIdleTimerDisabled = false
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            // Remaining time
            VStack(spacing: 2) {
                Text(engine.formattedTimeRemaining)
                    .font(BDDesign.Typography.monoBody)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                        Capsule()
                            .fill(pattern.accentColor)
                            .frame(width: geo.size.width * engine.sessionProgress)
                    }
                }
                .frame(width: 80, height: 3)
            }
            
            Spacer()
            
            // Zen mode
            Button {
                withAnimation(BDDesign.Motion.standard) {
                    zenMode.toggle()
                }
            } label: {
                Image(systemName: zenMode ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, BDDesign.Spacing.lg)
        .padding(.top, BDDesign.Spacing.sm)
    }
    
    // MARK: - Session Bottom Bar
    
    private var sessionBottomBar: some View {
        HStack(spacing: BDDesign.Spacing.xl) {
            // Cycles count
            VStack(spacing: 2) {
                Text("\(engine.completedCycles)")
                    .font(BDDesign.Typography.cardTitle)
                    .foregroundStyle(.white)
                Text("cycles")
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Pause / Resume
            Button {
                if engine.state == .active {
                    engine.pause()
                } else {
                    engine.resume()
                }
                if hapticsEnabled { HapticsManager.shared.tap() }
            } label: {
                Image(systemName: engine.state == .active ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(pattern.accentColor)
                    .frame(width: 64, height: 64)
                    .background(.white, in: Circle())
            }
            
            Spacer()
            
            // Stop
            Button {
                engine.stop()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("End")
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, BDDesign.Spacing.xl)
        .padding(.bottom, BDDesign.Spacing.xl)
    }
    
    // MARK: - Completion View
    
    private func completionView(geometry: GeometryProxy) -> some View {
        VStack(spacing: BDDesign.Spacing.xl) {
            Spacer()
            
            BreedyMascotView(mood: .celebrating, size: 100)
            
            VStack(spacing: BDDesign.Spacing.sm) {
                Text("Well done")
                    .font(BDDesign.Typography.sectionHeading)
                    .tracking(-1.28)
                    .foregroundStyle(.white)
                
                Text("You completed \(engine.completedCycles) cycles in \(formattedElapsed)")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            // Stats
            HStack(spacing: BDDesign.Spacing.lg) {
                completionStat(
                    value: formattedElapsed,
                    label: "Duration"
                )
                completionStat(
                    value: "\(engine.completedCycles)",
                    label: "Cycles"
                )
                completionStat(
                    value: "+\(calculateXP()) XP",
                    label: "Earned"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                UIApplication.shared.isIdleTimerDisabled = false
                let duration = Int(engine.elapsedSeconds)
                let cycles = engine.completedCycles
                onComplete(duration, cycles, true)
                onDismiss()
            } label: {
                Text("Done")
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(pattern.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable))
            }
            .padding(.horizontal, BDDesign.Spacing.xl)
            .padding(.bottom, BDDesign.Spacing.xl)
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
        LinearGradient(
            colors: [
                Color(hex: 0x0A0A0A),
                Color(hex: 0x111111),
                pattern.accentColor.opacity(0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
                .foregroundStyle(selectedDuration == seconds ? pattern.accentColor : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if selectedDuration == seconds {
                        Capsule().fill(.white.opacity(0.15))
                    } else {
                        Capsule().fill(.white.opacity(0.05))
                    }
                }
        }
    }
    
    // MARK: - Helpers
    
    private func configureEngine() {
        engine.configure(pattern: pattern, durationMode: .timed(seconds: selectedDuration))
        
        engine.onPhaseChange = { phase in
            if hapticsEnabled {
                HapticsManager.shared.phaseTransition(phase)
            }
        }
        
        engine.onSessionComplete = {
            if hapticsEnabled {
                HapticsManager.shared.sessionComplete()
            }
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
}

#Preview {
    BreathingSessionView(
        pattern: BreathingPresets.boxBreathing,
        mood: .focus,
        onComplete: { _, _, _ in },
        onDismiss: {}
    )
}
