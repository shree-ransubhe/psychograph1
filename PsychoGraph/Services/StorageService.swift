import Foundation

/// Snapshot of all app data for iCloud backup/restore.
struct PsychoGraphBackup: Codable {
    var checkInStore: CheckInStore
    var socialBenevolence: [String: Double]
    var monthBenevolenceOverride: [String: Double]
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var profileName: String
    var profileMobile: String
    var profilePAN: String
    var profileAddress: String
    var profileKendra: String
    var profileEmail: String
    var profileAKSK: String
    var backupDate: Date
}

final class StorageService {
    static let shared = StorageService()
    private let key = "psychograph_checkins"
    private let socialBenevolenceKey = "psychograph_social_benevolence_hrs"
    private let reminderEnabledKey = "psychograph_reminder_enabled"
    private let reminderHourKey = "psychograph_reminder_hour"
    private let reminderMinuteKey = "psychograph_reminder_minute"
    private let profileNameKey = "psychograph_profile_name"
    private let profileMobileKey = "psychograph_profile_mobile"
    private let profilePANKey = "psychograph_profile_pan"
    private let profileAddressKey = "psychograph_profile_address"
    private let profileKendraKey = "psychograph_profile_kendra"
    private let profileEmailKey = "psychograph_profile_email"
    private let profileAKSKKey = "psychograph_profile_aksk"
    private let monthBenevolenceKey = "psychograph_month_benevolence_override"
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Reminder settings (daily check-in notification)

    var reminderEnabled: Bool {
        get { defaults.object(forKey: reminderEnabledKey) as? Bool ?? false }
        set { defaults.set(newValue, forKey: reminderEnabledKey) }
    }

    var reminderHour: Int {
        get {
            let h = defaults.integer(forKey: reminderHourKey)
            return (defaults.object(forKey: reminderHourKey) != nil) ? h : 8
        }
        set { defaults.set(newValue, forKey: reminderHourKey) }
    }

    var reminderMinute: Int {
        get {
            let m = defaults.integer(forKey: reminderMinuteKey)
            return (defaults.object(forKey: reminderMinuteKey) != nil) ? m : 0
        }
        set { defaults.set(newValue, forKey: reminderMinuteKey) }
    }

    // MARK: - Profile (user-editable: name, mobile, PAN, address, kendra; admin-only: email, AKSK)

    var profileName: String {
        get { defaults.string(forKey: profileNameKey) ?? "" }
        set { defaults.set(newValue, forKey: profileNameKey) }
    }

    var profileMobile: String {
        get { defaults.string(forKey: profileMobileKey) ?? "" }
        set { defaults.set(newValue, forKey: profileMobileKey) }
    }

    var profilePAN: String {
        get { defaults.string(forKey: profilePANKey) ?? "" }
        set { defaults.set(newValue, forKey: profilePANKey) }
    }

    var profileAddress: String {
        get { defaults.string(forKey: profileAddressKey) ?? "" }
        set { defaults.set(newValue, forKey: profileAddressKey) }
    }

    var profileKendra: String {
        get { defaults.string(forKey: profileKendraKey) ?? "" }
        set { defaults.set(newValue, forKey: profileKendraKey) }
    }

    /// Email ID – unique identifier, set from backend by admin (invite-only). User cannot change.
    var profileEmail: String {
        get { defaults.string(forKey: profileEmailKey) ?? "" }
        set { defaults.set(newValue, forKey: profileEmailKey) }
    }

    /// AKSK number – unique identifier, set from backend by admin (invite-only). User cannot change.
    var profileAKSK: String {
        get { defaults.string(forKey: profileAKSKKey) ?? "" }
        set { defaults.set(newValue, forKey: profileAKSKKey) }
    }

    /// User is allowed to use the app only after first-launch login (AKSK + email) matches bundle.
    var isAuthenticated: Bool {
        !profileEmail.isEmpty && !profileAKSK.isEmpty
    }

    /// Max allowed invite-only users per bundle (closed user group for testing).
    private static let maxBundleProfiles = 25

    /// Clears auth profile (email, AKSK) and posts userDidLogout so the app shows LoginView again. Use for testing login.
    func logout() {
        profileEmail = ""
        profileAKSK = ""
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    /// First-launch login: username = AKSK, password = email. Validates against DefaultProfile.plist in bundle (up to 25 users).
    /// If match, saves to UserDefaults and returns true; otherwise returns false.
    func validateAndLogin(username: String, password: String) -> Bool {
        let profiles = loadBundleProfiles()
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = profiles.first(where: { $0.aksk == user && $0.email == pass }) else { return false }
        profileAKSK = match.aksk
        profileEmail = match.email
        return true
    }

    /// Load invite list from DefaultProfile.plist in app bundle (no server). Up to 25 (email, AKSK) pairs.
    /// Supports: (1) "Profiles" array of dicts with ProfileEmail + ProfileAKSK, or (2) legacy single ProfileEmail + ProfileAKSK at top level.
    private func loadBundleProfiles() -> [(email: String, aksk: String)] {
        guard let url = Bundle.main.url(forResource: "DefaultProfile", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any] else {
            return []
        }
        if let arr = dict["Profiles"] as? [[String: Any]] {
            let pairs = arr.prefix(Self.maxBundleProfiles).compactMap { item -> (email: String, aksk: String)? in
                let email = (item["ProfileEmail"] as? String) ?? ""
                let aksk = (item["ProfileAKSK"] as? String) ?? ""
                return (!email.isEmpty && !aksk.isEmpty) ? (email, aksk) : nil
            }
            return pairs
        }
        let email = (dict["ProfileEmail"] as? String) ?? ""
        let aksk = (dict["ProfileAKSK"] as? String) ?? ""
        if !email.isEmpty && !aksk.isEmpty { return [(email, aksk)] }
        return []
    }

    func loadStore() -> CheckInStore {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(CheckInStore.self, from: data) else {
            return CheckInStore()
        }
        return decoded
    }

    func saveStore(_ store: CheckInStore) {
        guard let data = try? JSONEncoder().encode(store) else { return }
        defaults.set(data, forKey: key)
    }

    func setCheckIn(dateKey: String, categoryId: String, subcategoryIndex: Int, value: Int) {
        var store = loadStore()
        store.set(dateKey: dateKey, categoryId: categoryId, subcategoryIndex: subcategoryIndex, value: value)
        saveStore(store)
    }

    func getCheckIn(dateKey: String, categoryId: String, subcategoryIndex: Int) -> Int? {
        loadStore().get(dateKey: dateKey, categoryId: categoryId, subcategoryIndex: subcategoryIndex)
    }

    func getMonthData(year: Int, month: Int) -> CheckInStore {
        loadStore()
    }

    // MARK: - Social Benevolence hours (per day)

    func setSocialBenevolenceHours(dateKey: String, hours: Double) {
        var dict = loadSocialBenevolence()
        if hours > 0 {
            dict[dateKey] = hours
        } else {
            dict.removeValue(forKey: dateKey)
        }
        saveSocialBenevolence(dict)
    }

    func getSocialBenevolenceHours(dateKey: String) -> Double {
        loadSocialBenevolence()[dateKey] ?? 0
    }

    func getMonthTotalSocialBenevolence(year: Int, month: Int) -> Double {
        let prefix = String(format: "%04d-%02d-", year, month)
        return loadSocialBenevolence()
            .filter { $0.key.hasPrefix(prefix) }
            .values
            .reduce(0, +)
    }

    /// Sum of all stored social benevolence hours (all time).
    func getCumulativeSocialBenevolence() -> Double {
        loadSocialBenevolence().values.reduce(0, +)
    }

    // MARK: - Month-level benevolence override (for PDF export; used when user enters श्रमानंद तास per month)

    func setMonthBenevolenceOverride(year: Int, month: Int, hours: Double) {
        var dict = loadMonthBenevolenceOverride()
        let key = String(format: "%04d-%02d", year, month)
        if hours >= 0 {
            dict[key] = hours
        } else {
            dict.removeValue(forKey: key)
        }
        saveMonthBenevolenceOverride(dict)
    }

    func getMonthBenevolenceOverride(year: Int, month: Int) -> Double? {
        let key = String(format: "%04d-%02d", year, month)
        return loadMonthBenevolenceOverride()[key]
    }

    /// Effective month total for display/PDF: override if set, else sum of daily social benevolence.
    func getMonthBenevolenceForReport(year: Int, month: Int) -> Double {
        if let override = getMonthBenevolenceOverride(year: year, month: month) {
            return override
        }
        return getMonthTotalSocialBenevolence(year: year, month: month)
    }

    private func loadMonthBenevolenceOverride() -> [String: Double] {
        guard let data = defaults.data(forKey: monthBenevolenceKey),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveMonthBenevolenceOverride(_ dict: [String: Double]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        defaults.set(data, forKey: monthBenevolenceKey)
    }

    private func loadSocialBenevolence() -> [String: Double] {
        guard let data = defaults.data(forKey: socialBenevolenceKey),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveSocialBenevolence(_ dict: [String: Double]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        defaults.set(data, forKey: socialBenevolenceKey)
    }

    // MARK: - iCloud backup / restore

    /// Export current data for backup (e.g. to iCloud).
    func exportForBackup() -> PsychoGraphBackup {
        PsychoGraphBackup(
            checkInStore: loadStore(),
            socialBenevolence: loadSocialBenevolence(),
            monthBenevolenceOverride: loadMonthBenevolenceOverride(),
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            profileName: profileName,
            profileMobile: profileMobile,
            profilePAN: profilePAN,
            profileAddress: profileAddress,
            profileKendra: profileKendra,
            profileEmail: profileEmail,
            profileAKSK: profileAKSK,
            backupDate: Date()
        )
    }

    /// Apply a backup onto current storage (overwrites local data).
    func applyBackup(_ backup: PsychoGraphBackup) {
        saveStore(backup.checkInStore)
        saveSocialBenevolence(backup.socialBenevolence)
        saveMonthBenevolenceOverride(backup.monthBenevolenceOverride)
        reminderEnabled = backup.reminderEnabled
        reminderHour = backup.reminderHour
        reminderMinute = backup.reminderMinute
        profileName = backup.profileName
        profileMobile = backup.profileMobile
        profilePAN = backup.profilePAN
        profileAddress = backup.profileAddress
        profileKendra = backup.profileKendra
        profileEmail = backup.profileEmail
        profileAKSK = backup.profileAKSK
    }

    /// True if there is any check-in or profile data (used to offer restore when empty).
    var hasAnyUserData: Bool {
        let store = loadStore()
        let hasCheckIns = !store.entries.isEmpty
        let hasProfile = !profileName.isEmpty || !profileMobile.isEmpty || !profileKendra.isEmpty
        let hasBenevolence = !loadSocialBenevolence().isEmpty
        return hasCheckIns || hasProfile || hasBenevolence
    }

    // MARK: - Clear report data

    private static let reportDataClearedOnceKey = "psychograph_report_data_cleared_once"

    /// Clears all report data: check-ins, social benevolence hours, and month benevolence overrides. Profile and reminder settings are kept. Posts PsychoGraphReportDataDidClear when done.
    func clearAllReportData() {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: socialBenevolenceKey)
        defaults.removeObject(forKey: monthBenevolenceKey)
        NotificationCenter.default.post(name: .psychographReportDataDidClear, object: nil)
    }

    /// Runs once per install to clear any previously seeded dummy report data. Call from app launch.
    func clearReportDataOnceIfNeeded() {
        guard !defaults.bool(forKey: Self.reportDataClearedOnceKey) else { return }
        clearAllReportData()
        defaults.set(true, forKey: Self.reportDataClearedOnceKey)
    }

}
