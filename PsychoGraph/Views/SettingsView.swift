import MessageUI
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    private let storage = StorageService.shared
    private let notificationService = NotificationService.shared

    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderDate()
    @State private var permissionDenied: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var showExportReport = false
    @State private var showBackupShareSheet = false
    @State private var showMailCompose = false
    @State private var backupFileURL: URL?
    @State private var showRestorePicker = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var showFailureLogView = false
    @State private var showFailureLogShare = false
    @State private var showClearReportDataConfirmation = false

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
                profileSection
                remindersSection
                exportReportSection
                reportDataSection
                dataBackupSection
                failureLogSection
                Section {
                    Text("Beta-1.0")
                        .font(AppTheme.captionSecondary())
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .onAppear(perform: loadSettings)
            .sheet(isPresented: $showExportReport) {
                ExportReportView()
            }
            .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
                Button("Open Settings", action: openSystemSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable notifications in Settings to receive daily check-in reminders.")
            }
            .sheet(isPresented: $showBackupShareSheet) {
                if let url = backupFileURL, FileManager.default.fileExists(atPath: url.path) {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showMailCompose) {
                if let url = backupFileURL, FileManager.default.fileExists(atPath: url.path) {
                    MailComposeView(
                        toRecipients: storage.profileEmail.isEmpty ? [] : [storage.profileEmail],
                        subject: "PsychoGraph backup",
                        body: "PsychoGraph data backup attached. Keep this file to restore later.",
                        attachmentURL: url,
                        onDismiss: {
                            showMailCompose = false
                            backupFileURL = nil
                        }
                    )
                }
            }
            .fileImporter(
                isPresented: $showRestorePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleRestoreResult(result)
            }
            .alert("Restore", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(restoreAlertMessage)
            }
            .sheet(isPresented: $showFailureLogView) {
                FailureLogView()
            }
            .sheet(isPresented: $showFailureLogShare) {
                if let url = FailureLogger.shared.logFileURL, FileManager.default.fileExists(atPath: url.path) {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Clear all report data?", isPresented: $showClearReportDataConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    storage.clearAllReportData()
                }
            } message: {
                Text("This will remove all check-ins and benevolence hours from the report. Profile and reminder settings are kept. This cannot be undone.")
            }
        }
    }

    private var profileSection: some View {
        Section {
            NavigationLink {
                ProfileView()
            } label: {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("Profile")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        } header: {
            Text("Profile")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("View and edit your profile. Email and AKSK are set by admin.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
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

    private var reportDataSection: some View {
        Section {
            Button(role: .destructive) {
                showClearReportDataConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear all report data")
                }
            }
        } header: {
            Text("Report data")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("Removes all check-ins and benevolence hours shown on the Report tab. Use this to start fresh.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var dataBackupSection: some View {
        Section {
            if !storage.hasAnyUserData {
                Text("You have no data yet. Add check-ins or profile info, then export a backup.")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Button {
                exportBackupAndShare()
            } label: {
                HStack {
                    Image(systemName: "envelope.badge")
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Email backup (JSON)")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Button {
                showRestorePicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Restore from backup")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        } header: {
            Text("Data Backup")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        } footer: {
            Text("Export your data as a JSON file (To: your email) or restore from a backup JSON file on this device. iCloud backup will be added later.")
                .font(AppTheme.captionSecondary())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var exportReportSection: some View {
        Section {
            Button {
                showExportReport = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.primary)
                    Text("Export Report as PDF")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        } header: {
            Text("Export Report")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("Select a date range and save your report as PDF. Up to 2 months fit on one A4 page.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var failureLogSection: some View {
        Section {
            Button {
                showFailureLogView = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("View failure log")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            Button {
                showFailureLogShare = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("Export failure log")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .disabled(FailureLogger.shared.readLogContent().isEmpty)
        } header: {
            Text("Debug / Failure log")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        } footer: {
            Text("Logs login failures and errors (e.g. iCloud, PDF). Export and share to help debug issues.")
                .font(AppTheme.captionSecondary())
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

    // MARK: - Email backup (JSON)

    private func exportBackupAndShare() {
        let backup = storage.exportForBackup()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let name = "PsychoGraph_backup_\(formatter.string(from: backup.backupDate)).json"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup)
            try data.write(to: fileURL)
            backupFileURL = fileURL
            if MFMailComposeViewController.canSendMail() {
                showMailCompose = true
            } else {
                showBackupShareSheet = true
            }
        } catch {
            FailureLogger.shared.logError(error, context: "Email Backup")
        }
    }

    private func handleRestoreResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                restoreAlertMessage = "No file selected."
                showRestoreAlert = true
                return
            }
            restoreFromURL(url)
        case .failure(let error):
            restoreAlertMessage = error.localizedDescription
            showRestoreAlert = true
        }
    }

    private func restoreFromURL(_ url: URL) {
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if needsSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(PsychoGraphBackup.self, from: data)
            StorageService.shared.applyBackup(backup)
            loadSettings()
            restoreAlertMessage = "Restore complete. Your data has been restored."
            showRestoreAlert = true
        } catch {
            FailureLogger.shared.logError(error, context: "Restore from backup")
            restoreAlertMessage = "Could not restore: \(error.localizedDescription)"
            showRestoreAlert = true
        }
    }
}

#Preview("Settings") {
    SettingsView()
}
