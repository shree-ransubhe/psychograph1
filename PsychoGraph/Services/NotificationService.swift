import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func scheduleDailyReminder(at hour: Int = 8, minute: Int = 0) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["psychograph_daily"])

        let content = UNMutableNotificationContent()
        content.title = "PsychoGraph Check-in"
        content.body = "How is your state of mind today? Tap to log."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "psychograph_daily", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["psychograph_daily"])
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
