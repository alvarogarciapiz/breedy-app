import SwiftUI

// MARK: - Sessions Library View

struct SessionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: PatternCategory? = nil
    @State private var customPatterns: [BreathingPattern] = []
    @State private var showBuilder = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Category filter
                    categoryFilter
                    
                    // Preset sessions
                    presetSection
                    
                    // Custom sessions
                    customSection
                }
                .padding(.horizontal, BDDesign.Spacing.lg)
                .padding(.bottom, BDDesign.Spacing.section)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showBuilder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showBuilder) {
                CustomSessionBuilderView { pattern in
                    statsManager.saveCustomPattern(pattern)
                    loadCustomPatterns()
                }
            }
        }
        .onAppear { loadCustomPatterns() }
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BDDesign.Spacing.sm) {
                categoryPill(nil, label: "All")
                
                ForEach(PatternCategory.allCases.filter { $0 != .custom }, id: \.self) { category in
                    categoryPill(category, label: category.rawValue)
                }
            }
        }
        .padding(.top, BDDesign.Spacing.sm)
    }
    
    private func categoryPill(_ category: PatternCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category
        
        return Button {
            withAnimation(BDDesign.Motion.quick) {
                selectedCategory = category
            }
            HapticsManager.shared.selection()
        } label: {
            Text(label)
                .font(BDDesign.Typography.button)
                .foregroundStyle(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.7) : BDDesign.Colors.gray600))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(BDDesign.Colors.gray900)
                    } else {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : .white)
                            .overlay {
                                Capsule()
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                            }
                    }
                }
        }
    }
    
    // MARK: - Preset Section
    
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            Text("Breathing Patterns")
                .font(BDDesign.Typography.cardTitle)
                .tracking(-0.96)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            ForEach(filteredPresets, id: \.id) { pattern in
                SessionCardView(pattern: pattern) {
                    HapticsManager.shared.tap()
                    appState.startSession(pattern: pattern)
                }
            }
        }
    }
    
    // MARK: - Custom Section
    
    private var customSection: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.md) {
            HStack {
                Text("Custom Patterns")
                    .font(BDDesign.Typography.cardTitle)
                    .tracking(-0.96)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                
                Spacer()
                
                if !customPatterns.isEmpty {
                    Text("\(customPatterns.count)")
                        .bdPillBadge()
                }
            }
            
            if customPatterns.isEmpty {
                emptyCustomState
            } else {
                ForEach(customPatterns, id: \.id) { pattern in
                    SessionCardView(pattern: pattern) {
                        appState.startSession(pattern: pattern)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            statsManager.deleteCustomPattern(id: pattern.id)
                            loadCustomPatterns()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private var emptyCustomState: some View {
        Button {
            showBuilder = true
        } label: {
            VStack(spacing: BDDesign.Spacing.sm) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(BDDesign.Colors.gray400)
                
                Text("Create your first custom pattern")
                    .font(BDDesign.Typography.bodySmall)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            .frame(maxWidth: .infinity)
            .padding(BDDesign.Spacing.xl)
            .bdCard()
        }
    }
    
    // MARK: - Helpers
    
    private var filteredPresets: [BreathingPattern] {
        guard let category = selectedCategory else {
            return BreathingPresets.allPresets
        }
        return BreathingPresets.allPresets.filter { $0.category == category }
    }
    
    private func loadCustomPatterns() {
        customPatterns = statsManager.fetchCustomPatterns()
    }
}

// MARK: - Custom Session Builder

struct CustomSessionBuilderView: View {
    let onSave: (BreathingPattern) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var title = ""
    @State private var inhale: Double = 4
    @State private var hold1: Double = 4
    @State private var exhale: Double = 4
    @State private var hold2: Double = 4
    @State private var selectedIcon = "wind"
    @State private var selectedColorHex: UInt = 0x0A72EF
    @State private var selectedMood: MascotMood = .calm
    
    private let icons = ["wind", "leaf.fill", "moon.fill", "bolt.fill", "heart.fill", "water.waves", "sun.max.fill", "sparkles"]
    private let colors: [(String, UInt)] = [
        ("Blue", 0x0A72EF),
        ("Purple", 0x7928CA),
        ("Pink", 0xDE1D8D),
        ("Red", 0xFF5B4F),
        ("Green", 0x4CAF50),
        ("Teal", 0x009688),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BDDesign.Spacing.xl) {
                    // Preview
                    patternPreview
                    
                    // Title
                    VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
                        Text("Pattern Name")
                            .font(BDDesign.Typography.bodySemibold)
                            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                        
                        TextField("My Pattern", text: $title)
                            .font(BDDesign.Typography.body)
                            .padding(BDDesign.Spacing.md)
                            .background {
                                RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: BDDesign.Radius.standard)
                                            .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                                    }
                            }
                    }
                    
                    // Timing sliders
                    timingSection
                    
                    // Icon picker
                    iconPicker
                    
                    // Color picker
                    colorPicker
                    
                    // Mood picker
                    moodPicker
                }
                .padding(BDDesign.Spacing.lg)
            }
            .background(colorScheme == .dark ? Color(hex: 0x0A0A0A) : BDDesign.Colors.gray50)
            .navigationTitle("Custom Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let pattern = BreathingPattern(
                            title: title.isEmpty ? "Custom Pattern" : title,
                            inhale: inhale,
                            hold1: hold1,
                            exhale: exhale,
                            hold2: hold2,
                            icon: selectedIcon,
                            colorHex: selectedColorHex,
                            category: .custom,
                            isCustom: true,
                            mascotMood: selectedMood
                        )
                        onSave(pattern)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var patternPreview: some View {
        HStack(spacing: BDDesign.Spacing.md) {
            phaseBlock("In", seconds: inhale, color: Color(hex: selectedColorHex))
            if hold1 > 0 { phaseBlock("Hold", seconds: hold1, color: Color(hex: selectedColorHex).opacity(0.7)) }
            phaseBlock("Out", seconds: exhale, color: Color(hex: selectedColorHex))
            if hold2 > 0 { phaseBlock("Hold", seconds: hold2, color: Color(hex: selectedColorHex).opacity(0.7)) }
        }
        .padding(BDDesign.Spacing.md)
        .bdCard()
    }
    
    private func phaseBlock(_ label: String, seconds: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1fs", seconds))
                .font(BDDesign.Typography.cardTitle)
                .foregroundStyle(color)
            Text(label)
                .font(BDDesign.Typography.caption)
                .foregroundStyle(BDDesign.Colors.gray500)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var timingSection: some View {
        VStack(spacing: BDDesign.Spacing.md) {
            timingSlider("Inhale", value: $inhale, range: 1...12)
            timingSlider("Hold", value: $hold1, range: 0...12)
            timingSlider("Exhale", value: $exhale, range: 1...12)
            timingSlider("Hold 2", value: $hold2, range: 0...12)
        }
    }
    
    private func timingSlider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(BDDesign.Typography.bodyMedium)
                    .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
                Spacer()
                Text(String(format: "%.1fs", value.wrappedValue))
                    .font(BDDesign.Typography.monoCaption)
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            Slider(value: value, in: range, step: 0.5)
                .tint(Color(hex: selectedColorHex))
        }
    }
    
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            Text("Icon")
                .font(BDDesign.Typography.bodySemibold)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(selectedIcon == icon ? .white : BDDesign.Colors.gray600)
                            .frame(width: 48, height: 48)
                            .background {
                                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                                    .fill(selectedIcon == icon ? Color(hex: selectedColorHex) : (colorScheme == .dark ? Color.white.opacity(0.06) : BDDesign.Colors.gray50))
                            }
                    }
                }
            }
        }
    }
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            Text("Color")
                .font(BDDesign.Typography.bodySemibold)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            HStack(spacing: 12) {
                ForEach(colors, id: \.1) { (name, hex) in
                    Button {
                        selectedColorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedColorHex == hex {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 3)
                                        .frame(width: 36, height: 36)
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: BDDesign.Spacing.sm) {
            Text("Mascot Mood")
                .font(BDDesign.Typography.bodySemibold)
                .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MascotMood.allCases, id: \.self) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.expression)
                                    .font(.system(size: 24))
                                Text(mood.rawValue.capitalized)
                                    .font(BDDesign.Typography.caption)
                                    .foregroundStyle(selectedMood == mood ? Color(hex: selectedColorHex) : BDDesign.Colors.gray500)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: BDDesign.Radius.comfortable)
                                    .fill(selectedMood == mood ? Color(hex: selectedColorHex).opacity(0.1) : .clear)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SessionsView()
        .environment(AppState())
        .environment(StatsManager())
}
