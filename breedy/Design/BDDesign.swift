import SwiftUI

// MARK: - Breedy Design System
// Adapted from Vercel Design System for native iOS
// Uses SF Pro (Apple native) with Vercel spacing & color philosophy

enum BDDesign {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary
        static let primary = Color(hex: 0x171717)
        static let background = Color.white
        static let surface = Color.white
        static let surfaceTint = Color(hex: 0xFAFAFA)
        
        // Neutral scale
        static let gray900 = Color(hex: 0x171717)
        static let gray600 = Color(hex: 0x4D4D4D)
        static let gray500 = Color(hex: 0x666666)
        static let gray400 = Color(hex: 0x808080)
        static let gray100 = Color(hex: 0xEBEBEB)
        static let gray50 = Color(hex: 0xFAFAFA)
        
        // Interactive
        static let linkBlue = Color(hex: 0x0072F5)
        static let focusBlue = Color(hue: 212/360, saturation: 1.0, brightness: 0.48)
        static let badgeBlueBg = Color(hex: 0xEBF5FF)
        static let badgeBlueText = Color(hex: 0x0068D6)
        
        // Accent — functional, not decorative
        static let accentCalm = Color(hex: 0x0A72EF)    // Blue — focus/calm
        static let accentEnergy = Color(hex: 0xFF5B4F)   // Coral-red — energy
        static let accentSleep = Color(hex: 0x7928CA)    // Purple — sleep
        static let accentAnxiety = Color(hex: 0xDE1D8D)  // Pink — relief
        static let accentFocus = Color(hex: 0x0070F3)    // Bright blue — focus
        
        // Mood colors
        static func moodColor(for mood: MoodState) -> Color {
            switch mood {
            case .calm: return accentCalm
            case .focus: return accentFocus
            case .sleep: return accentSleep
            case .energy: return accentEnergy
            case .anxietyRelief: return accentAnxiety
            }
        }
        
        // Dark mode adaptations
        static let primaryAdaptive = Color("PrimaryAdaptive")
        static let backgroundAdaptive = Color("BackgroundAdaptive")
    }
    
    // MARK: - Typography
    // Using native SF Pro per DESIGN.md instruction: "For typography use native Apple one"
    
    enum Typography {
        static let displayHero = Font.system(size: 34, weight: .semibold, design: .default)
        static let sectionHeading = Font.system(size: 28, weight: .semibold, design: .default)
        static let subheadingLarge = Font.system(size: 24, weight: .semibold, design: .default)
        static let subheading = Font.system(size: 24, weight: .regular, design: .default)
        static let cardTitle = Font.system(size: 20, weight: .semibold, design: .default)
        static let cardTitleLight = Font.system(size: 20, weight: .medium, design: .default)
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .medium, design: .default)
        static let bodySemibold = Font.system(size: 15, weight: .semibold, design: .default)
        static let button = Font.system(size: 14, weight: .medium, design: .default)
        static let buttonSmall = Font.system(size: 14, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let monoBody = Font.system(size: 15, weight: .regular, design: .monospaced)
        static let monoCaption = Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
        
        // Breathing session display
        static let breathPhase = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let breathTimer = Font.system(size: 64, weight: .light, design: .rounded)
        static let breathCountdown = Font.system(size: 48, weight: .thin, design: .rounded)
        static let statNumber = Font.system(size: 40, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing (8px base unit)
    
    enum Spacing {
        static let xs: CGFloat      = 4
        static let sm: CGFloat      = 8
        static let md: CGFloat      = 12
        static let lg: CGFloat      = 16
        static let xl: CGFloat      = 32
        static let xxl: CGFloat     = 40
        static let section: CGFloat = 48
    }
    
    // MARK: - Radius
    
    enum Radius {
        static let micro: CGFloat       = 2
        static let subtle: CGFloat      = 4
        static let standard: CGFloat    = 6
        static let comfortable: CGFloat = 8
        static let image: CGFloat       = 12
        static let large: CGFloat       = 16
        static let pill: CGFloat        = 9999
    }
    
    // MARK: - Shadows (Vercel shadow-as-border philosophy)
    
    enum Shadows {
        static let borderShadow = Color.black.opacity(0.08)
        static let subtleElevation = Color.black.opacity(0.04)
        static let innerGlow = Color(hex: 0xFAFAFA)
    }
    
    // MARK: - Animation
    
    enum Motion {
        static let quick: Animation = .easeOut(duration: 0.2)
        static let standard: Animation = .easeInOut(duration: 0.35)
        static let slow: Animation = .easeInOut(duration: 0.5)
        static let breath: Animation = .easeInOut(duration: 1.0)
        static let spring: Animation = .spring(response: 0.5, dampingFraction: 0.8)
        
        static func breathAnimation(duration: Double) -> Animation {
            .easeInOut(duration: duration)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - View Modifiers

struct BDCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .fill(colorScheme == .dark ? Color(hex: 0x1C1C1E) : .white)
                    .shadow(color: BDDesign.Shadows.borderShadow, radius: 0, x: 0, y: 0)
                    .shadow(color: BDDesign.Shadows.subtleElevation, radius: 2, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.06)
                            : Color.black.opacity(0.08),
                        lineWidth: 1
                    )
            }
    }
}

struct BDPillBadge: ViewModifier {
    let backgroundColor: Color
    let textColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(BDDesign.Typography.captionMedium)
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
    }
}

struct BDPrimaryButton: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .font(BDDesign.Typography.bodyMedium)
            .foregroundStyle(.white)
            .padding(.horizontal, BDDesign.Spacing.lg)
            .padding(.vertical, BDDesign.Spacing.md)
            .background(BDDesign.Colors.gray900, in: RoundedRectangle(cornerRadius: BDDesign.Radius.standard))
    }
}

struct BDSecondaryButton: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .font(BDDesign.Typography.bodyMedium)
            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            .padding(.horizontal, BDDesign.Spacing.lg)
            .padding(.vertical, BDDesign.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                    .fill(colorScheme == .dark ? Color(hex: 0x2C2C2E) : .white)
                    .overlay {
                        RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                            .strokeBorder(Color(hex: 0xEBEBEB), lineWidth: 1)
                    }
            }
    }
}

extension View {
    func bdCard() -> some View {
        modifier(BDCardStyle())
    }
    
    func bdPillBadge(
        background: Color = BDDesign.Colors.badgeBlueBg,
        text: Color = BDDesign.Colors.badgeBlueText
    ) -> some View {
        modifier(BDPillBadge(backgroundColor: background, textColor: text))
    }
    
    func bdPrimaryButton() -> some View {
        modifier(BDPrimaryButton())
    }
    
    func bdSecondaryButton() -> some View {
        modifier(BDSecondaryButton())
    }
}
