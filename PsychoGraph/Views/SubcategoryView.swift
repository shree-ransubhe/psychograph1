import SwiftUI

struct SubcategoryView: View {
    let date: Date
    let initialCategory: PsychoCategory
    let onDone: () -> Void
    let onCompleteAndGoToReport: () -> Void

    @State private var selectedIndices: [String: Set<Int>] = [:]
    @State private var currentPageIndex: Int = 0

    private var dateKey: String {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: start)
    }

    private var categories: [PsychoCategory] { PsychoCategory.allCases }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPageIndex) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    subcategoryPage(category: category)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear { currentPageIndex = categories.firstIndex(where: { $0.id == initialCategory.id }) ?? 0 }

            Button("Done") {
                saveAllAndComplete()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle(initialCategory.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { onDone() }
            }
        }
        .onAppear { loadSelections() }
    }

    @ViewBuilder
    private func subcategoryPage(category: PsychoCategory) -> some View {
        let binding = Binding(
            get: { selectedIndices[category.rawValue] ?? [] },
            set: { selectedIndices[category.rawValue] = $0 }
        )
        List {
            Section(category.displayName) {
                ForEach(Array(category.subcategoryLabels.enumerated()), id: \.offset) { index, label in
                    subcategoryToggle(binding: binding, index: index, label: label)
                }
            }
        }
    }

    private func subcategoryToggle(binding: Binding<Set<Int>>, index: Int, label: String) -> some View {
        Toggle(isOn: Binding(
            get: { binding.wrappedValue.contains(index) },
            set: { newValue in
                var set = binding.wrappedValue
                if newValue { set.insert(index) } else { set.remove(index) }
                binding.wrappedValue = set
            }
        )) {
            Text(label.isEmpty ? "—" : label)
        }
    }

    private func loadSelections() {
        let storage = StorageService.shared
        for category in PsychoCategory.allCases {
            var set: Set<Int> = []
            for index in 0..<category.subcategoryCount {
                if storage.getCheckIn(dateKey: dateKey, categoryId: category.rawValue, subcategoryIndex: index) == 1 {
                    set.insert(index)
                }
            }
            selectedIndices[category.rawValue] = set
        }
    }

    private func saveAllAndComplete() {
        let storage = StorageService.shared
        for category in PsychoCategory.allCases {
            let indices = selectedIndices[category.rawValue] ?? []
            for index in 0..<category.subcategoryCount {
                storage.setCheckIn(
                    dateKey: dateKey,
                    categoryId: category.rawValue,
                    subcategoryIndex: index,
                    value: indices.contains(index) ? 1 : 0
                )
            }
        }
        onCompleteAndGoToReport()
    }
}
