import Foundation

/// One daily check-in: which subcategory was marked for a given day
struct CheckInRecord: Codable, Identifiable {
    var id: String { "\(dateKey)-\(categoryId)-\(subcategoryIndex)" }
    let dateKey: String       // "yyyy-MM-dd"
    let categoryId: String    // "A", "B", "C", "D"
    let subcategoryIndex: Int // 0-based index within category
    var value: Int           // 0 = unchecked, 1 = checked (or scale 0–3 if you add levels later)

    init(dateKey: String, categoryId: String, subcategoryIndex: Int, value: Int = 1) {
        self.dateKey = dateKey
        self.categoryId = categoryId
        self.subcategoryIndex = subcategoryIndex
        self.value = value
    }
}

/// All check-ins for a month: dateKey -> [categoryId -> [subcategoryIndex -> value]]
struct CheckInStore: Codable {
    var entries: [String: [String: [Int: Int]]] = [:]

    mutating func set(dateKey: String, categoryId: String, subcategoryIndex: Int, value: Int) {
        if entries[dateKey] == nil { entries[dateKey] = [:] }
        if entries[dateKey]![categoryId] == nil { entries[dateKey]![categoryId] = [:] }
        entries[dateKey]![categoryId]![subcategoryIndex] = value
    }

    func get(dateKey: String, categoryId: String, subcategoryIndex: Int) -> Int? {
        entries[dateKey]?[categoryId]?[subcategoryIndex]
    }

    func get(dateKey: String) -> [String: [Int: Int]]? { entries[dateKey] }
}
