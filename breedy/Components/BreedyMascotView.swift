import SwiftUI

// MARK: - Breedy Mascot View

struct BreedyMascotView: View {
    let mood: MascotMood
    var size: CGFloat = 120
    var isBreathing: Bool = false
    var breathScale: CGFloat = 1.0
    
    @State private var idleAnimation = false
    @State private var blinkTimer = false
    @State private var isBlinking = false
    
    var body: some View {
        ZStack {
            // Aura glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [moodColor.opacity(0.15), moodColor.opacity(0)],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .scaleEffect(idleAnimation ? 1.05 : 0.95)
            
            // Main body
            ZStack {
                // Body circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                moodColor.opacity(0.2),
                                moodColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        Circle()
                            .strokeBorder(moodColor.opacity(0.3), lineWidth: 1.5)
                    }
                
                // Face
                VStack(spacing: size * 0.03) {
                    // Eyes
                    HStack(spacing: size * 0.15) {
                        EyeView(size: size * 0.1, isBlinking: isBlinking, mood: mood)
                        EyeView(size: size * 0.1, isBlinking: isBlinking, mood: mood)
                    }
                    
                    // Mouth
                    MouthView(size: size * 0.15, mood: mood)
                }
                .offset(y: size * 0.02)
                
                // Cheeks
                HStack(spacing: size * 0.35) {
                    Circle()
                        .fill(moodColor.opacity(0.15))
                        .frame(width: size * 0.12, height: size * 0.08)
                    Circle()
                        .fill(moodColor.opacity(0.15))
                        .frame(width: size * 0.12, height: size * 0.08)
                }
                .offset(y: size * 0.1)
            }
            .scaleEffect(isBreathing ? breathScale : (idleAnimation ? 1.02 : 0.98))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                idleAnimation = true
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = true
                }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = false
                }
            }
        }
    }
    
    private var moodColor: Color {
        switch mood {
        case .calm:        return BDDesign.Colors.accentCalm
        case .happy:       return Color(hex: 0x4CAF50)
        case .sleepy:      return BDDesign.Colors.accentSleep
        case .energetic:   return BDDesign.Colors.accentEnergy
        case .supportive:  return BDDesign.Colors.accentAnxiety
        case .celebrating: return Color(hex: 0xFFD700)
        case .meditating:  return BDDesign.Colors.accentCalm
        case .breathing:   return BDDesign.Colors.accentFocus
        }
    }
    
}

// MARK: - Eye

private struct EyeView: View {
    let size: CGFloat
    let isBlinking: Bool
    let mood: MascotMood
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            if isBlinking || mood == .sleepy {
                // Closed eye
                Capsule()
                    .fill(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .frame(width: size, height: size * 0.15)
            } else {
                // Open eye
                Circle()
                    .fill(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    .frame(width: size, height: size)
                
                // Pupil highlight
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: size * 0.15, y: -size * 0.15)
            }
        }
    }
}

// MARK: - Mouth

private struct MouthView: View {
    let size: CGFloat
    let mood: MascotMood
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let fillColor = colorScheme == .dark ? Color.white : BDDesign.Colors.gray900
        
        switch mood {
        case .happy, .celebrating, .energetic:
            // Wide smile
            HappyMouth(size: size)
                .stroke(fillColor, lineWidth: 1.5)
                .frame(width: size, height: size * 0.5)
        case .sleepy:
            // Small O
            Circle()
                .stroke(fillColor, lineWidth: 1.5)
                .frame(width: size * 0.4, height: size * 0.4)
        case .calm, .meditating, .breathing:
            // Gentle smile
            GentleSmile(size: size)
                .stroke(fillColor, lineWidth: 1.5)
                .frame(width: size * 0.7, height: size * 0.3)
        case .supportive:
            // Warm smile
            GentleSmile(size: size)
                .stroke(fillColor, lineWidth: 1.5)
                .frame(width: size * 0.8, height: size * 0.35)
        }
    }
}

private struct HappyMouth: Shape {
    let size: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct GentleSmile: Shape {
    let size: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

#Preview {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            BreedyMascotView(mood: .calm, size: 80)
            BreedyMascotView(mood: .happy, size: 80)
            BreedyMascotView(mood: .sleepy, size: 80)
        }
        HStack(spacing: 24) {
            BreedyMascotView(mood: .energetic, size: 80)
            BreedyMascotView(mood: .celebrating, size: 80)
            BreedyMascotView(mood: .meditating, size: 80)
        }
    }
    .padding()
}
