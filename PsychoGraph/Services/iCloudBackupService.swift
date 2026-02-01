import Foundation

/// Backup and restore app data to/from iCloud Documents. Requires iCloud capability in the app.
final class iCloudBackupService {
    static let shared = iCloudBackupService()
    private let fileManager = FileManager.default
    private let backupFileName = "psychograph_backup.json"

    private init() {}

    /// iCloud container ID; must match entitlements. Pass nil to use first container.
    private var containerIdentifier: String? { "iCloud.\(Bundle.main.bundleIdentifier ?? "com.psychograph.PsychoGraph")" }

    /// Root URL for this app's iCloud container. Nil if iCloud is unavailable or not signed in.
    func ubiquityContainerURL() async -> URL? {
        let containerID = containerIdentifier
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let url = FileManager.default.url(forUbiquityContainerIdentifier: containerID)
                continuation.resume(returning: url)
            }
        }
    }

    /// Documents directory inside the iCloud container.
    private func iCloudDocumentsURL() async -> URL? {
        guard let base = await ubiquityContainerURL() else { return nil }
        let documents = base.appendingPathComponent("Documents", isDirectory: true)
        try? fileManager.createDirectory(at: documents, withIntermediateDirectories: true)
        return documents
    }

    /// Backup file URL in iCloud Documents.
    private func backupFileURL() async -> URL? {
        guard let documents = await iCloudDocumentsURL() else { return nil }
        return documents.appendingPathComponent(backupFileName)
    }

    /// Backup current app data to iCloud. Returns backup date on success.
    func backupToiCloud() async throws -> Date {
        guard let fileURL = await backupFileURL() else {
            throw iCloudBackupError.iCloudUnavailable
        }
        let backup = StorageService.shared.exportForBackup()
        let data = try JSONEncoder().encode(backup)
        try data.write(to: fileURL)
        return backup.backupDate
    }

    /// Restore app data from iCloud. Returns the restored backup (with its date) on success.
    func restoreFromiCloud() async throws -> PsychoGraphBackup {
        guard let fileURL = await backupFileURL() else {
            throw iCloudBackupError.iCloudUnavailable
        }
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw iCloudBackupError.noBackupFound
        }
        let data = try Data(contentsOf: fileURL)
        let backup = try JSONDecoder().decode(PsychoGraphBackup.self, from: data)
        StorageService.shared.applyBackup(backup)
        return backup
    }

    /// Last backup date (from file modification date). Nil if no backup or iCloud unavailable.
    func lastBackupDate() async -> Date? {
        guard let fileURL = await backupFileURL() else { return nil }
        guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let date = attrs[.modificationDate] as? Date else {
            return nil
        }
        return date
    }

    /// Whether a backup exists in iCloud (for showing "Restore" option).
    func hasBackupIniCloud() async -> Bool {
        guard let fileURL = await backupFileURL() else { return false }
        return fileManager.fileExists(atPath: fileURL.path)
    }
}

enum iCloudBackupError: LocalizedError {
    case iCloudUnavailable
    case noBackupFound

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud is not available. Sign in to iCloud in Settings on this device. If you build the app yourself, iCloud backup requires a paid Apple Developer Program membership."
        case .noBackupFound:
            return "No backup found in iCloud. Backup your data first."
        }
    }
}
