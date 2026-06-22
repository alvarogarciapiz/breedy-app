import SwiftUI

struct LevelUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let newLevel: Int
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : BDDesign.Colors.gray50)
                .ignoresSafeArea()
            
            // Confetti effect (simplified using particles or basic shapes)
            GeometryReader { geo in
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(randomColor())
                        .frame(width: 8, height: 8)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: isVisible ? CGFloat.random(in: 0...geo.size.height) : -50
                        )
                        .animation(
                            .interpolatingSpring(stiffness: 50, damping: 5)
                            .delay(Double.random(in: 0...0.5)),
                            value: isVisible
                        )
                }
            }
            
            VStack(spacing: BDDesign.Spacing.xl) {
                Spacer()
                
                // Mascot or icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BDDesign.Colors.accentFocus, BDDesign.Colors.accentCalm],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: BDDesign.Colors.accentFocus.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)
                .opacity(isVisible ? 1 : 0)
                
                VStack(spacing: BDDesign.Spacing.sm) {
                    Text("Level Up!")
                        .font(BDDesign.Typography.displayHero)
                        .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                    
                    Text("You've reached Level \(newLevel)")
                        .font(BDDesign.Typography.sectionHeading)
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                    
                    Text("Your consistent practice is paying off. New auras and badges might be unlocked!")
                        .font(BDDesign.Typography.body)
                        .foregroundStyle(BDDesign.Colors.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BDDesign.Spacing.xl)
                }
                .offset(y: isVisible ? 0 : 40)
                .opacity(isVisible ? 1 : 0)
                
                Spacer()
                
                Button {
                    HapticsManager.shared.tap()
                    dismiss()
                } label: {
                    Text("Continue")
                        .bdPrimaryButton()
                }
                .padding(.horizontal, BDDesign.Spacing.xl)
                .padding(.bottom, BDDesign.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeIn.delay(1.0), value: isVisible)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isVisible = true
                scale = 1.0
            }
            HapticsManager.shared.milestone()
        }
    }
    
    private func randomColor() -> Color {
        let colors = [BDDesign.Colors.accentCalm, BDDesign.Colors.accentFocus, BDDesign.Colors.accentEnergy, BDDesign.Colors.accentSleep]
        return colors.randomElement() ?? .white
    }
}

#Preview {
    LevelUpView(newLevel: 5)
}
