import UserNotifications
import SwiftUI

// MARK: - Notification Manager

@Observable
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    
    private(set) var isAuthorized: Bool = false
    
    // MARK: - Settings Keys
    
    @ObservationIgnored
    @AppStorage("reminder_morning_enabled") var morningReminderEnabled = false
    @ObservationIgnored
    @AppStorage("reminder_morning_hour") var morningHour = 7
    @ObservationIgnored
    @AppStorage("reminder_morning_minute") var morningMinute = 30
    
    @ObservationIgnored
    @AppStorage("reminder_work_enabled") var workBreakEnabled = false
    @ObservationIgnored
    @AppStorage("reminder_work_hour") var workBreakHour = 12
    @ObservationIgnored
    @AppStorage("reminder_work_minute") var workBreakMinute = 0
    
    @ObservationIgnored
    @AppStorage("reminder_evening_enabled") var eveningReminderEnabled = false
    @ObservationIgnored
    @AppStorage("reminder_evening_hour") var eveningHour = 21
    @ObservationIgnored
    @AppStorage("reminder_evening_minute") var eveningMinute = 0
    
    @ObservationIgnored
    @AppStorage("reminder_streak_enabled") var streakReminderEnabled = true
    
    private init() {
        Task { await checkAuthorization() }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                scheduleAllReminders()
            }
            return granted
        } catch {
            return false
        }
    }
    
    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Scheduling
    
    func scheduleAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        if morningReminderEnabled {
            scheduleDaily(
                id: "breedy_morning",
                hour: morningHour,
                minute: morningMinute,
                title: "Good morning ☀️",
                body: "Start your day with a few mindful breaths."
            )
        }
        
        if workBreakEnabled {
            scheduleDaily(
                id: "breedy_work_break",
                hour: workBreakHour,
                minute: workBreakMinute,
                title: "Time for a break",
                body: "A quick breathing session can reset your focus."
            )
        }
        
        if eveningReminderEnabled {
            scheduleDaily(
                id: "breedy_evening",
                hour: eveningHour,
                minute: eveningMinute,
                title: "Wind down 🌙",
                body: "Prepare for restful sleep with a calming breath."
            )
        }
        
        if streakReminderEnabled {
            scheduleStreakReminder()
        }
    }
    
    private func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleStreakReminder() {
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak 🔥"
        content.body = "Just one minute to keep your breathing streak alive."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "breedy_streak", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
