import Foundation

final class StorageService {
    static let shared = StorageService()
    private let key = "psychograph_checkins"
    private let socialBenevolenceKey = "psychograph_social_benevolence_hrs"
    private let reminderEnabledKey = "psychograph_reminder_enabled"
    private let reminderHourKey = "psychograph_reminder_hour"
    private let reminderMinuteKey = "psychograph_reminder_minute"
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

    // MARK: - Sample data for testing Report / GraphView

    /// Seeds random check-ins for the given month so the report grid shows filled dots. Call when you need test data (e.g. GraphView .onAppear when that month has no entries).
    func seedSampleDataIfNeeded(year: Int, month: Int) {
        let prefix = String(format: "%04d-%02d-", year, month)
        let store = loadStore()
        let hasDataForMonth = store.entries.keys.contains { $0.hasPrefix(prefix) }
        if hasDataForMonth { return }

        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: dateFor(year: year, month: month)) else { return }
        var newStore = store
        var seed = UInt64(year * 100 + month)
        for day in range {
            let dateKey = String(format: "%04d-%02d-%02d", year, month, day)
            for category in PsychoCategory.allCases {
                for subIndex in 0..<category.subcategoryCount where !category.subcategoryLabels[subIndex].isEmpty {
                    if nextRandom(seed: &seed, max: 100) < 35 {
                        newStore.set(dateKey: dateKey, categoryId: category.rawValue, subcategoryIndex: subIndex, value: 1)
                    }
                }
            }
        }
        saveStore(newStore)
    }

    private func dateFor(year: Int, month: Int) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        return Calendar.current.date(from: c) ?? Date()
    }

    private func nextRandom(seed: inout UInt64, max: Int) -> Int {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return Int(truncatingIfNeeded: seed % UInt64(max))
    }
}
