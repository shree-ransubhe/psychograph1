import Foundation

final class StorageService {
    static let shared = StorageService()
    private let key = "psychograph_checkins"
    private let socialBenevolenceKey = "psychograph_social_benevolence_hrs"
    private let defaults = UserDefaults.standard

    private init() {}

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
}
