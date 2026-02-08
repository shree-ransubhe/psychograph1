import SwiftUI

struct AddTodaysGraphView: View {
    var initialDate: Date
    var onDismiss: () -> Void
    var onCompleteAndGoToReport: (Date) -> Void

    @State private var selectedDate: Date
    @State private var selectedCategory: PsychoCategory?

    init(initialDate: Date, onDismiss: @escaping () -> Void, onCompleteAndGoToReport: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onDismiss = onDismiss
        self.onCompleteAndGoToReport = onCompleteAndGoToReport
        _selectedDate = State(initialValue: initialDate)
        _selectedCategory = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Date") {
                    DatePicker("Log date", selection: $selectedDate, displayedComponents: .date)
                }

                Section("Category") {
                    ForEach(PsychoCategory.allCases) { category in
                        Button(category.displayName) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .navigationTitle("Log Psychograph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onDismiss() }
                }
            }
            .navigationDestination(item: $selectedCategory) { category in
                SubcategoryView(
                    date: $selectedDate,
                    initialCategory: category,
                    onDone: { selectedCategory = nil },
                    onCompleteAndGoToReport: { onCompleteAndGoToReport(selectedDate) }
                )
                .id(selectedDate)
            }
        }
    }
}
