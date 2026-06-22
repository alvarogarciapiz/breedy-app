import SwiftUI

// MARK: - Breathing Orb

struct BreathingOrbView: View {
    let phase: BreathPhase
    let progress: Double
    var phaseDuration: Double? = nil
    let accentColor: Color
    var size: CGFloat = 240
    var isActive: Bool = true
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 1. Outer Ethereal Glow (Breathes)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.4), accentColor.opacity(0.0)]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.8, height: size * 1.8)
                .blur(radius: size * 0.3)
                .scaleEffect(targetOrbScale)
            
            // 2. Slow Rotating Conic Core
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.1), accentColor.opacity(0.5), accentColor.opacity(0.1)]),
                        center: .center
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: size * 0.15)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(targetOrbScale)
            
            // 3. Crisp Glass Edge
            Circle()
                .fill(.white.opacity(0.05))
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .frame(width: size, height: size)
                .shadow(color: accentColor.opacity(0.3), radius: 30, x: 0, y: 15)
                .scaleEffect(targetOrbScale)
            
            // 4. Central Energy Core
            Circle()
                .fill(accentColor)
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: size * 0.2)
                .blendMode(.screen)
                .scaleEffect(targetOrbScale * 1.2)
            
            // 5. Delicate Progress Ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 2)
                    
                Circle()
                    .trim(from: 0, to: isActive ? progress : 0)
                    .stroke(
                        .white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .shadow(color: .white.opacity(0.5), radius: 4)
                    .animation(.linear(duration: 0.05), value: progress)
            }
            .frame(width: size * 1.08, height: size * 1.08)
            .rotationEffect(.degrees(-90))
            .scaleEffect(targetOrbScale)
        }
        .frame(width: size, height: size)
        .animation(.linear(duration: 0.05), value: targetOrbScale)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    private var targetOrbScale: CGFloat {
        if !isActive { return 0.6 }
        
        let start: CGFloat
        let end: CGFloat = phase.orbScale
        
        switch phase {
        case .inhale: start = 0.6
        case .hold1:  start = 1.0
        case .exhale: start = 1.0
        case .hold2:  start = 0.6
        }
        
        // Apply smoothstep (easeInOut) mathematically
        let easedProgress = progress * progress * (3.0 - 2.0 * progress)
        let current = start + (end - start) * easedProgress
        
        return current * 1.05
    }
}

struct SessionCardView: View {
    let pattern: BreathingPattern
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetail = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BDDesign.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(pattern.accentColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: pattern.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(pattern.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pattern.title)
                        .font(BDDesign.Typography.bodySemibold)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text(!pattern.description.isEmpty ? pattern.description : patternDescription)
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Info button
                if !pattern.scienceDetail.isEmpty {
                    Button {
                        showDetail = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(BDDesign.Colors.gray400)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(pattern.accentColor)
                    .padding(10)
                    .background(pattern.accentColor.opacity(0.1), in: Circle())
            }
            .padding(BDDesign.Spacing.md)
            .bdCard()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            PatternDetailSheet(pattern: pattern, onStart: onTap)
        }
    }
    
    private var patternDescription: String {
        let parts = [
            "\(Int(pattern.inhaleSeconds))s in",
            pattern.hold1Seconds > 0 ? "\(Int(pattern.hold1Seconds))s hold" : nil,
            "\(Int(pattern.exhaleSeconds))s out",
            pattern.hold2Seconds > 0 ? "\(Int(pattern.hold2Seconds))s hold" : nil
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Pattern Detail Sheet

struct PatternDetailSheet: View {
    let pattern: BreathingPattern
    let onStart: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Hero
                    VStack(spacing: BDDesign.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(pattern.accentColor.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: pattern.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(pattern.accentColor)
                        }
                        
                        Text(pattern.title)
                            .font(BDDesign.Typography.sectionHeading)
                            .tracking(-1.28)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        
                        if !pattern.scienceBadge.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                Text(pattern.scienceBadge)
                                    .font(BDDesign.Typography.captionMedium)
                            }
                            .foregroundStyle(BDDesign.Colors.accentFocus)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(BDDesign.Colors.accentFocus.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.top, BDDesign.Spacing.md)
                    
                    // Benefit Tags
                    if !pattern.benefitTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(pattern.benefitTags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Image(systemName: tagIcon(for: tag))
                                            .font(.system(size: 10, weight: .semibold))
                                        Text(tag)
                                            .font(BDDesign.Typography.captionMedium)
                                    }
                                    .foregroundStyle(pattern.accentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(pattern.accentColor.opacity(0.1), in: Capsule())
                                }
                            }
                        }
                    }
                    
                    // Phase diagram
                    VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "waveform")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(BDDesign.Colors.gray500)
                            Text("Breathing Pattern")
                                .font(BDDesign.Typography.captionMedium)
                                .foregroundStyle(BDDesign.Colors.gray500)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(pattern.phases, id: \.0) { phase, duration in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(phaseColor(phase))
                                        .frame(height: CGFloat(duration) * 8)
                                    
                                    Text(phase.displayName)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(BDDesign.Colors.gray500)
                                    
                                    Text("\(Int(duration))s")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(BDDesign.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : BDDesign.Colors.gray50)
                        }
                    }
                    
                    // Science detail
                    if !pattern.scienceDetail.isEmpty {
                        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                            HStack(spacing: 6) {
                                Image(systemName: "brain")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BDDesign.Colors.accentFocus)
                                Text("The Science")
                                    .font(BDDesign.Typography.cardTitle)
                                    .tracking(-0.96)
                                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                            }
                            
                            Text(pattern.scienceDetail)
                                .font(BDDesign.Typography.bodySmall)
                                .foregroundStyle(BDDesign.Colors.gray600)
                                .lineSpacing(4)
                        }
                        .padding(BDDesign.Spacing.lg)
                        .bdCard()
                    }
                    
                    // One-line description
                    if !pattern.description.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 12))
                                .foregroundStyle(BDDesign.Colors.gray400)
                            Text(pattern.description)
                                .font(BDDesign.Typography.body)
                                .italic()
                                .foregroundStyle(BDDesign.Colors.gray500)
                        }
                        .padding(BDDesign.Spacing.md)
                    }
                    
                    // Start button
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onStart() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 14))
                            Text("Start Session")
                                .font(BDDesign.Typography.bodyMedium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pattern.accentColor, in: RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable))
                    }
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.xl)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BDDesign.Colors.gray400)
                            .padding(8)
                            .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray100))
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func phaseColor(_ phase: BreathPhase) -> Color {
        switch phase {
        case .inhale: return BDDesign.Colors.accentCalm
        case .hold1:  return BDDesign.Colors.accentFocus
        case .exhale: return BDDesign.Colors.accentSleep
        case .hold2:  return BDDesign.Colors.gray400
        }
    }
    
    private func tagIcon(for tag: String) -> String {
        if tag.contains("HRV") { return "heart.fill" }
        if tag.contains("Cortisol") { return "arrow.down.heart.fill" }
        if tag.contains("Sleep") || tag.contains("Melatonin") { return "moon.fill" }
        if tag.contains("Vagal") || tag.contains("Vagus") { return "brain.head.profile" }
        if tag.contains("Focus") || tag.contains("Alertness") { return "scope" }
        if tag.contains("Anxiety") || tag.contains("Heart Rate") { return "heart.fill" }
        if tag.contains("Energy") || tag.contains("Noradrenaline") { return "bolt.fill" }
        if tag.contains("Relaxation") || tag.contains("Muscle") { return "figure.mind.and.body" }
        if tag.contains("Resonance") || tag.contains("Nervous") { return "waveform.path" }
        if tag.contains("Blood Pressure") { return "drop.fill" }
        return "sparkles"
    }
}

// MARK: - Stat Tile

struct StatTileView: View {
    let title: String
    let value: String
    let icon: String
    var accentColor: Color = BDDesign.Colors.accentCalm
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor)
            
            Text(value)
                .font(BDDesign.Typography.cardTitle)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            Text(title)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
}

// MARK: - Mood Chip

struct MoodChipView: View {
    let mood: MoodState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mood.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : mood.color)
                
                Text(mood.rawValue)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : BDDesign.Colors.gray600)
            }
            .frame(width: 64, height: 64)
            .background {
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .fill(isSelected ? mood.color : mood.color.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
        .animation(BDDesign.Motion.quick, value: isSelected)
    }
}

// MARK: - Streak Badge

struct StreakBadgeView: View {
    let streak: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: BDDesign.Spacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundStyle(streakColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(BDDesign.Typography.bodySemibold)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Text(streakMessage)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            Spacer()
        }
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
    
    private var streakColor: Color {
        switch streak {
        case 0:     return BDDesign.Colors.gray400
        case 1...3: return Color(hex: 0xD9A05B) // Muted Gold
        case 4...7: return Color(hex: 0xD48C5B) // Warm Amber
        default:    return BDDesign.Colors.accentEnergy // Terracotta
        }
    }
    
    private var streakMessage: String {
        switch streak {
        case 0:      return "Start breathing to build your streak"
        case 1:      return "Great start! Keep it going"
        case 2...3:  return "Building momentum"
        case 4...6:  return "You're on fire!"
        case 7...13: return "A full week! Impressive"
        case 14...29: return "Two weeks strong"
        default:     return "Legendary consistency"
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(size: geo.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func createParticles(size: CGSize) {
        let colors: [Color] = [
            BDDesign.Colors.accentCalm,
            BDDesign.Colors.accentEnergy,
            BDDesign.Colors.accentSleep,
            BDDesign.Colors.accentAnxiety,
            Color(hex: 0xFFD700)
        ]
        
        for i in 0..<30 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(
                    x: CGFloat.random(in: 0...max(size.width, 300)),
                    y: -20
                ),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // Animate particles
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            withAnimation(.easeOut(duration: 2).delay(delay)) {
                particles[i].position.y = max(size.height, 800) + 20
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview("Components") {
    ScrollView {
        VStack(spacing: 16) {
            BreathingOrbView(
                phase: .inhale,
                progress: 0.5,
                accentColor: BDDesign.Colors.accentCalm
            )
            
            SessionCardView(pattern: BreathingPresets.boxBreathing) {}
            
            HStack {
                StatTileView(title: "Minutes", value: "42", icon: "clock.fill")
                StatTileView(title: "Sessions", value: "12", icon: "wind")
            }
            
            StreakBadgeView(streak: 7)
            
            HStack(spacing: 8) {
                ForEach(MoodState.allCases) { mood in
                    MoodChipView(mood: mood, isSelected: mood == .calm) {}
                }
            }
        }
        .padding()
    }
}
