import SwiftUI

struct SettingsView: View {
    private let storage = StorageService.shared
    private let notificationService = NotificationService.shared

    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderDate()
    @State private var permissionDenied: Bool = false
    @State private var showPermissionAlert: Bool = false

    private static func defaultReminderDate() -> Date {
        let s = StorageService.shared
        var components = DateComponents()
        components.hour = s.reminderHour
        components.minute = s.reminderMinute
        return Calendar.current.date(from: components) ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    }

    var body: some View {
        NavigationStack {
            List {
                remindersSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear(perform: loadSettings)
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("Open Settings", action: openSystemSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable notifications in Settings to receive daily check-in reminders.")
            }
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Daily check-in reminder", isOn: $reminderEnabled)
                .tint(AppTheme.primary)
                .onChange(of: reminderEnabled) { _, newValue in
                    storage.reminderEnabled = newValue
                    if newValue {
                        requestPermissionAndSchedule()
                    } else {
                        notificationService.cancelDailyReminder()
                    }
                }

            if reminderEnabled {
                DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, newDate in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        storage.reminderHour = components.hour ?? 8
                        storage.reminderMinute = components.minute ?? 0
                        notificationService.scheduleDailyReminder(at: storage.reminderHour, minute: storage.reminderMinute)
                    }
            }
        } header: {
            Text("Reminders")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("You'll get a notification at the chosen time each day to log your state of mind.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private func loadSettings() {
        reminderEnabled = storage.reminderEnabled
        var components = DateComponents()
        components.hour = storage.reminderHour
        components.minute = storage.reminderMinute
        reminderTime = Calendar.current.date(from: components) ?? Self.defaultReminderDate()
        if reminderEnabled {
            notificationService.scheduleDailyReminder(at: storage.reminderHour, minute: storage.reminderMinute)
        }
    }

    private func requestPermissionAndSchedule() {
        notificationService.requestAuthorization { granted in
            if granted {
                notificationService.scheduleDailyReminder(at: storage.reminderHour, minute: storage.reminderMinute)
            } else {
                reminderEnabled = false
                storage.reminderEnabled = false
                showPermissionAlert = true
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Settings") {
    SettingsView()
}
