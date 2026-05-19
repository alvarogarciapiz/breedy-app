import SwiftUI

// MARK: - Breedy Mascot View
// Uses the 4 illustrated mascot images: breedy_awake, breedy_sleep, breedy_breathe, breedy_greet

struct BreedyMascotView: View {
    let mood: MascotMood
    var size: CGFloat = 120
    var isBreathing: Bool = false
    var breathScale: CGFloat = 1.0
    
    @State private var idleFloat = false
    
    var body: some View {
        ZStack {
            // Soft aura glow behind the mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [moodColor.opacity(0.18), moodColor.opacity(0)],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(idleFloat ? 1.06 : 0.94)
                .blur(radius: 2)
            
            // Mascot image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .scaleEffect(isBreathing ? breathScale : 1.0)
                .offset(y: idleFloat ? -3 : 3)
                .shadow(
                    color: moodColor.opacity(0.2),
                    radius: 12,
                    y: 6
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                idleFloat = true
            }
        }
    }
    
    // MARK: - Image Mapping
    
    /// Maps each MascotMood to one of the 4 mascot images
    private var imageName: String {
        switch mood {
        case .calm, .meditating, .supportive:
            return "breedy_breathe"
        case .happy, .celebrating, .energetic:
            return "breedy_greet"
        case .sleepy:
            return "breedy_sleep"
        case .happySleep:
            return "breedy_happy_sleep"
        case .breathing:
            return "breedy_breathe"
        }
    }
    
    // MARK: - Mood Color (for aura glow)
    
    private var moodColor: Color {
        switch mood {
        case .calm:        return BDDesign.Colors.accentCalm
        case .happy:       return Color(hex: 0x4CAF50)
        case .sleepy:      return BDDesign.Colors.accentSleep
        case .happySleep:  return BDDesign.Colors.accentSleep
        case .energetic:   return BDDesign.Colors.accentEnergy
        case .supportive:  return BDDesign.Colors.accentAnxiety
        case .celebrating: return Color(hex: 0xFFD700)
        case .meditating:  return BDDesign.Colors.accentCalm
        case .breathing:   return BDDesign.Colors.accentFocus
        }
    }
}

// MARK: - Breedy Image View (Standalone helper for direct image usage)
// Use this when you want a specific image without mood mapping

struct BreedyImageView: View {
    let imageName: String
    var size: CGFloat = 120
    var showAura: Bool = true
    var auraColor: Color = BDDesign.Colors.accentCalm
    
    @State private var idleFloat = false
    
    var body: some View {
        ZStack {
            if showAura {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [auraColor.opacity(0.15), auraColor.opacity(0)],
                            center: .center,
                            startRadius: size * 0.15,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.3, height: size * 1.3)
                    .scaleEffect(idleFloat ? 1.05 : 0.95)
                    .blur(radius: 2)
            }
            
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .offset(y: idleFloat ? -2 : 2)
                .shadow(
                    color: auraColor.opacity(0.15),
                    radius: 10,
                    y: 5
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.8)
                .repeatForever(autoreverses: true)
            ) {
                idleFloat = true
            }
        }
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
        
        // Direct image usage
        HStack(spacing: 24) {
            BreedyImageView(imageName: "breedy_awake", size: 80)
            BreedyImageView(imageName: "breedy_breathe", size: 80, auraColor: BDDesign.Colors.accentFocus)
        }
    }
    .padding()
}
