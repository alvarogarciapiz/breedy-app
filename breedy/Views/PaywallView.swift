import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var showCloseButton: Bool = false
    
    @State private var selectedTier: SubscriptionTier = .annual
    @State private var animateFeatures = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color(hex: 0x0A0A0A) : .white,
                    colorScheme == .dark ? Color(hex: 0x0A0A12) : Color(hex: 0xF0F4FF),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Close button (Settings only)
                    if showCloseButton {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(BDDesign.Colors.gray500)
                                    .padding(10)
                                    .background(
                                        Circle().fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50)
                                    )
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Hero
                    heroSection
                    
                    // Features
                    featuresSection
                    
                    // Social proof
                    socialProof
                    
                    // Pricing
                    pricingSection
                    
                    // CTA
                    ctaButton
                    
                    // Fine print
                    finePrint
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(subscriptionManager.purchaseError ?? "Something went wrong")
        }
        .onAppear {
            withAnimation(BDDesign.Motion.slow.delay(0.3)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Hero
    
    private var heroSection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            BreedyImageView(imageName: "breedy_greet", size: 140, auraColor: Color(hex: 0xFFD700))
                .padding(.top, BDDesign.Spacing.lg)
            
            Text("Unlock Your\nFull Potential")
                .font(BDDesign.Typography.displayHero)
                .tracking(-2.0)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                .multilineTextAlignment(.center)
            
            Text(personalizedSubtitle)
                .font(BDDesign.Typography.bodySmall)
                .foregroundStyle(BDDesign.Colors.gray500)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    private var personalizedSubtitle: String {
        let goal = appState.userGoal
        if !goal.isEmpty {
            return "Your personalized plan to \(goal.lowercased()) is ready.\nSubscribe to start your journey."
        }
        return "Science-backed breathing exercises,\npersonalized just for you."
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            ForEach(Array(SubscriptionManager.premiumFeatures.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: BDDesign.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        Text(feature.subtitle)
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    
                    Spacer()
                }
                .padding(BDDesign.Spacing.md)
                .opacity(animateFeatures ? 1 : 0)
                .offset(y: animateFeatures ? 0 : 10)
                .animation(BDDesign.Motion.standard.delay(Double(index) * 0.08), value: animateFeatures)
            }
        }
    }
    
    // MARK: - Social Proof
    
    private var socialProof: some View {
        HStack(spacing: BDDesign.Spacing.md) {
            // Avatar cluster
            HStack(spacing: -8) {
                let colors = [BDDesign.Colors.accentFocus, BDDesign.Colors.accentCalm, BDDesign.Colors.accentSleep]
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(color)
                        .background(
                            Circle().fill(colorScheme == .dark ? Color(hex: 0x0A0A0A) : .white)
                        )
                        .overlay(
                            Circle().stroke(colorScheme == .dark ? Color(hex: 0x0A0A0A) : .white, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0xFFD700))
                    }
                }
                
                Text("Join our growing community")
                    .font(BDDesign.Typography.captionMedium)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
        }
        .padding(.vertical, BDDesign.Spacing.sm)
    }
    
    // MARK: - Pricing
    
    private var pricingSection: some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            // Annual (Best Value)
            pricingCard(tier: .annual, isRecommended: true)
            
            // Monthly
            pricingCard(tier: .monthly, isRecommended: false)
        }
    }
    
    private func pricingCard(tier: SubscriptionTier, isRecommended: Bool) -> some View {
        let isSelected = selectedTier == tier
        
        return Button {
            selectedTier = tier
            HapticsManager.shared.selection()
        } label: {
            VStack(spacing: 0) {
                if isRecommended {
                    Text("BEST VALUE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(BDDesign.Colors.accentCalm)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tier.displayName)
                            .font(BDDesign.Typography.bodyMedium)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        
                        Text(tier.billingDescription)
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tier.price)
                            .font(BDDesign.Typography.cardTitle)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        
                        Text(tier.pricePerMonth)
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? BDDesign.Colors.accentCalm : BDDesign.Colors.gray400)
                        .padding(.leading, 8)
                }
                .padding(BDDesign.Spacing.lg)
            }
            .clipShape(RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable))
            .overlay {
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .strokeBorder(
                        isSelected ? BDDesign.Colors.accentCalm : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .background(
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .fill(colorScheme == .dark ? Color(hex: 0x1C1C1E) : .white)
            )
        }
        .buttonStyle(.plain)
        .animation(BDDesign.Motion.quick, value: isSelected)
    }
    
    // MARK: - CTA
    
    private var ctaButton: some View {
        Button {
            Task {
                let success = await subscriptionManager.purchase(selectedTier)
                if !success {
                    showError = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Your Journey")
                        .font(BDDesign.Typography.bodyMedium)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .fill(
                        LinearGradient(
                            colors: [BDDesign.Colors.accentCalm, BDDesign.Colors.accentFocus],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: BDDesign.Colors.accentCalm.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(subscriptionManager.isPurchasing)
    }
    
    // MARK: - Fine Print
    
    private var finePrint: some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            Button {
                Task { _ = await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(BDDesign.Typography.button)
                    .foregroundStyle(BDDesign.Colors.accentCalm)
            }
            
            Text("Cancel anytime · No commitment")
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray400)
            
            HStack(spacing: BDDesign.Spacing.lg) {
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray400)
                
                Link("Privacy", destination: URL(string: "https://apps.lvrpiz.com/privacy-and-terms")!)
                    .font(BDDesign.Typography.caption)
                    .foregroundStyle(BDDesign.Colors.gray400)
            }
        }
        .padding(.bottom, BDDesign.Spacing.lg)
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
        .environment(AppState())
}
