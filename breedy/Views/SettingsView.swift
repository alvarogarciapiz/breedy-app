import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(StatsManager.self) private var statsManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("voiceCuesEnabled") private var voiceCuesEnabled = false
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("mascotEnabled") private var mascotEnabled = true
    @AppStorage("mascotIntensity") private var mascotIntensity = "normal"
    @AppStorage("privacyMode") private var privacyMode = false
    
    @State private var showExportSheet = false
    @State private var exportData: Data?
    @State private var showResetAlert = false
    @State private var showReminders = false
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription
                subscriptionSection
                
                // Your Profile
                profileSection
                
                // Session preferences
                sessionSection
                
                // Appearance
                appearanceSection
                
                // Mascot
                mascotSection
                
                // Notifications
                notificationSection
                
                // Privacy & Data
                privacySection
                
                // About
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showReminders) {
                RemindersSettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(showCloseButton: true)
            }
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    // In production, clear SwiftData container
                }
            } message: {
                Text("This will permanently delete all your sessions, streaks, and progress. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0xFFD700))
                        Text("Premium")
                            .font(BDDesign.Typography.bodyMedium)
                    }
                    Text(subscriptionManager.statusText)
                        .font(BDDesign.Typography.caption)
                        .foregroundStyle(BDDesign.Colors.gray500)
                    if let since = subscriptionManager.memberSince {
                        Text("Member since \(since)")
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray400)
                    }
                }
                Spacer()
            }
            
            Button {
                showPaywall = true
            } label: {
                Label("Manage Subscription", systemImage: "creditcard")
            }
            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
        } header: {
            Text("Subscription")
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            if !appState.userName.isEmpty {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(appState.userName)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            
            if !appState.userGoal.isEmpty {
                HStack {
                    Text("Goal")
                    Spacer()
                    Text(appState.userGoal)
                        .foregroundStyle(BDDesign.Colors.gray500)
                }
            }
            
            HStack {
                Text("Daily Target")
                Spacer()
                Text("\(appState.dailyGoalMinutes) min")
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
        } header: {
            Text("Your Profile")
        } footer: {
            Text("Personalization from your onboarding choices.")
        }
    }
    
    // MARK: - Session Section
    
    private var sessionSection: some View {
        Section {
            Toggle("Sound Effects", isOn: $soundEnabled)
                .tint(BDDesign.Colors.accentCalm)
            
            Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                .tint(BDDesign.Colors.accentCalm)
            
            Toggle("Voice Cues", isOn: $voiceCuesEnabled)
                .tint(BDDesign.Colors.accentCalm)
        } header: {
            Text("Session")
        } footer: {
            Text("Haptics provide gentle feedback during phase transitions.")
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $selectedTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
    }
    
    // MARK: - Mascot Section
    
    private var mascotSection: some View {
        Section {
            Toggle("Show Breedy", isOn: $mascotEnabled)
                .tint(BDDesign.Colors.accentCalm)
            
            if mascotEnabled {
                Picker("Intensity", selection: $mascotIntensity) {
                    Text("Minimal").tag("minimal")
                    Text("Normal").tag("normal")
                    Text("Playful").tag("playful")
                }
            }
        } header: {
            Text("Companion")
        } footer: {
            Text("Adjust how present Breedy is throughout the app.")
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationSection: some View {
        Section("Reminders") {
            Button {
                showReminders = true
            } label: {
                HStack {
                    Label("Manage Reminders", systemImage: "bell.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BDDesign.Colors.gray400)
                }
            }
            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            Toggle("Privacy Mode", isOn: $privacyMode)
                .tint(BDDesign.Colors.accentCalm)
            
            Button {
                if let data = statsManager.exportData() {
                    exportData = data
                    showExportSheet = true
                }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
            .sheet(isPresented: $showExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }
        } header: {
            Text("Privacy & Data")
        } footer: {
            Text("Your data stays on your device. No accounts, no tracking.")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            HStack {
                Text("Built with")
                Spacer()
                Text("❤️ and SwiftUI")
                    .foregroundStyle(BDDesign.Colors.gray500)
            }
            
            Button {
                Task { _ = await subscriptionManager.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
            .foregroundStyle(colorScheme == .dark ? .white : BDDesign.Colors.gray900)
        }
    }
}

// MARK: - Reminders Settings View

struct RemindersSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage("reminder_morning_enabled") private var morningEnabled = false
    @AppStorage("reminder_morning_hour") private var morningHour = 7
    @AppStorage("reminder_morning_minute") private var morningMinute = 30
    @AppStorage("reminder_work_enabled") private var workEnabled = false
    @AppStorage("reminder_work_hour") private var workHour = 12
    @AppStorage("reminder_work_minute") private var workMinute = 0
    @AppStorage("reminder_evening_enabled") private var eveningEnabled = false
    @AppStorage("reminder_evening_hour") private var eveningHour = 21
    @AppStorage("reminder_evening_minute") private var eveningMinute = 0
    @AppStorage("reminder_streak_enabled") private var streakEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    reminderRow(
                        title: "Morning Reminder",
                        subtitle: "Start your day mindfully",
                        icon: "sunrise.fill",
                        isEnabled: $morningEnabled,
                        hour: $morningHour,
                        minute: $morningMinute
                    )
                    
                    reminderRow(
                        title: "Work Break",
                        subtitle: "Reset focus during the day",
                        icon: "briefcase.fill",
                        isEnabled: $workEnabled,
                        hour: $workHour,
                        minute: $workMinute
                    )
                    
                    reminderRow(
                        title: "Evening Unwind",
                        subtitle: "Wind down before sleep",
                        icon: "moon.fill",
                        isEnabled: $eveningEnabled,
                        hour: $eveningHour,
                        minute: $eveningMinute
                    )
                } header: {
                    Text("Daily Reminders")
                }
                
                Section {
                    Toggle("Streak Protection", isOn: $streakEnabled)
                        .tint(BDDesign.Colors.accentEnergy)
                } header: {
                    Text("Smart Reminders")
                } footer: {
                    Text("Get a gentle nudge at 8 PM if you haven't breathed today to protect your streak.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        NotificationManager.shared.scheduleAllReminders()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func reminderRow(title: String, subtitle: String, icon: String, isEnabled: Binding<Bool>, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        VStack(spacing: BDDesign.Spacing.sm) {
            Toggle(isOn: isEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(BDDesign.Typography.bodyMedium)
                        Text(subtitle)
                            .font(BDDesign.Typography.caption)
                            .foregroundStyle(BDDesign.Colors.gray500)
                    }
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(BDDesign.Colors.accentCalm)
                }
            }
            .tint(BDDesign.Colors.accentCalm)
            
            if isEnabled.wrappedValue {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = hour.wrappedValue
                            components.minute = minute.wrappedValue
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            hour.wrappedValue = components.hour ?? 7
                            minute.wrappedValue = components.minute ?? 0
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
            }
        }
    }
}



// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    nonisolated(unsafe) let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(StatsManager())
        .environment(SubscriptionManager())
}
