import UserNotifications

/// Identifier for the daily check-in reminder; used for scheduling and deep-link handling.
let kPsychographDailyReminderIdentifier = "psychograph_daily"

extension Notification.Name {
    /// Post this when the user taps the daily reminder notification; ContentView presents AddTodaysGraphView.
    static let openAddTodaysGraph = Notification.Name("PsychoGraphOpenAddTodaysGraph")
    /// Post when user logs out from Profile; app shows LoginView again.
    static let userDidLogout = Notification.Name("PsychoGraphUserDidLogout")
    /// Post when report data (check-ins, benevolence) is cleared; GraphView refreshes.
    static let psychographReportDataDidClear = Notification.Name("PsychoGraphReportDataDidClear")
}

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDailyReminder(at hour: Int = 8, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kPsychographDailyReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "PsychoGraph Check-in"
        content.body = "Log yesterday’s state of mind. Tap to open."
        content.sound = .default
        content.categoryIdentifier = "PSYCHOGRAPH_REMINDER"
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: kPsychographDailyReminderIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kPsychographDailyReminderIdentifier])
    }

    /// Reminds the user to compile the monthly report (e.g. 1st of each month). Report compilation is a separate module to be added later.
    func scheduleMonthlyReportReminder(dayOfMonth: Int = 1, hour: Int = 9, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["psychograph_monthly_report_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "PsychoGraph Monthly Report"
        content.body = "Don't forget to compile your monthly report when you're ready."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = dayOfMonth
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "psychograph_monthly_report_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelMonthlyReportReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["psychograph_monthly_report_reminder"])
    }
}
