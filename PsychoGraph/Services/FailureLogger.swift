import Foundation
import os.log

/// Logs failure and error data to a file in Documents for debugging. Users can export via Settings.
final class FailureLogger {
    static let shared = FailureLogger()

    private let fileName = "psychograph_failure_log.txt"
    private let maxLogSizeBytes = 512 * 1024 // 512 KB, then trim
    private let queue = DispatchQueue(label: "com.psychograph.failurelogger", qos: .utility)
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private init() {}

    /// Log a failure (e.g. login rejected). Does not log credentials.
    func logFailure(context: String, message: String) {
        let line = formatLine(context: context, message: message, error: nil)
        append(line)
    }

    /// Log an error (e.g. thrown Error from iCloud, PDF export).
    func logError(_ error: Error, context: String = "Error") {
        let message = error.localizedDescription
        let line = formatLine(context: context, message: message, error: error)
        append(line)
    }

    /// Log a generic message (e.g. "Export started", "Backup completed").
    func log(context: String, message: String) {
        let line = formatLine(context: context, message: message, error: nil)
        append(line)
    }

    private func formatLine(context: String, message: String, error: Error?) -> String {
        let ts = dateFormatter.string(from: Date())
        var parts = ["[\(ts)] [\(context)] \(message)"]
        if let e = error, (e as NSError).userInfo.isEmpty == false {
            parts.append("  userInfo: \((e as NSError).userInfo)")
        }
        return parts.joined(separator: "\n") + "\n"
    }

    private func append(_ text: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let url = self.logFileURL else { return }
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forWritingTo: url)
                    handle.seekToEndOfFile()
                    handle.write(Data(text.utf8))
                    try handle.close()
                } else {
                    try text.write(to: url, atomically: true, encoding: .utf8)
                }
                self.trimIfNeeded(at: url)
            } catch {
                os_log(.error, "FailureLogger could not write: %{public}@", error.localizedDescription)
            }
        }
    }

    private func trimIfNeeded(at url: URL) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64, size > maxLogSizeBytes else { return }
        do {
            let data = try Data(contentsOf: url)
            let str = String(data: data, encoding: .utf8) ?? ""
            let lines = str.components(separatedBy: "\n")
            let keep = lines.suffix(2000)
            let trimmed = "--- log trimmed ---\n" + keep.joined(separator: "\n")
            try trimmed.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            os_log(.error, "FailureLogger trim failed: %{public}@", error.localizedDescription)
        }
    }

    /// URL of the log file (for export). Nil if Documents is unavailable.
    var logFileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    /// Read current log content (for in-app view). Returns empty string if unavailable.
    func readLogContent() -> String {
        guard let url = logFileURL, FileManager.default.fileExists(atPath: url.path) else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    /// Clear the log file (optional; e.g. after export).
    func clearLog() {
        queue.async { [weak self] in
            guard let self = self, let url = self.logFileURL else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }
}
