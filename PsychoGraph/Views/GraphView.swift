import SwiftUI

struct GraphView: View {
    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    private let calendar = Calendar.current

    init() {
        let now = Date()
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: now))
        _selectedMonth = State(initialValue: Calendar.current.component(.month, from: now))
    }

    private var monthPrefix: String {
        String(format: "%04d-%02d-", selectedYear, selectedMonth)
    }

    private var dateKeysInMonth: [String] {
        StorageService.shared.loadStore().entries.keys
            .filter { $0.hasPrefix(monthPrefix) }
            .sorted()
    }

    private var socialBenevolenceTotal: Double {
        StorageService.shared.getMonthTotalSocialBenevolence(year: selectedYear, month: selectedMonth)
    }

    private let yearRange = 10
    private var yearChoices: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        return (currentYear - yearRange...currentYear).reversed()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(yearChoices, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Text("Social Benevolence (month total): \(formatHours(socialBenevolenceTotal)) hrs")
                }

                ForEach(PsychoCategory.allCases) { category in
                    Section(category.displayName) {
                        reportRows(category: category)
                    }
                }
            }
            .navigationTitle("Report")
        }
    }

    private func reportRows(category: PsychoCategory) -> some View {
        Group {
            let dateKeys = dateKeysInMonth
            if dateKeys.isEmpty {
                Text("No check-ins this month")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dateKeys, id: \.self) { dateKey in
                    if let categoryData = StorageService.shared.loadStore().entries[dateKey]?[category.rawValue],
                       !categoryData.isEmpty {
                        let labels = subcategoryLabelsChecked(categoryData: categoryData, category: category)
                        if !labels.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateKey)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(labels.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func subcategoryLabelsChecked(categoryData: [Int: Int], category: PsychoCategory) -> [String] {
        let labels = category.subcategoryLabels
        return categoryData
            .filter { $0.value == 1 }
            .map { labels[$0.key] }
            .filter { !$0.isEmpty }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var comps = DateComponents()
        comps.month = month
        comps.day = 1
        if let date = calendar.date(from: comps) {
            return formatter.string(from: date)
        }
        return String(month)
    }

    private func formatHours(_ hours: Double) -> String {
        if hours == Double(Int(hours)) {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}
