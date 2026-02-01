import SwiftUI
import UIKit

struct CheckInView: View {
    @Binding var showAddSheet: Bool

    @State private var socialBenevolenceDate = Date()
    @State private var socialBenevolenceHoursText = ""

    private var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: socialBenevolenceDate)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Add Today's Graph") { showAddSheet = true }
                }

                Section("Social Benevolence (hrs)") {
                    DatePicker("Date", selection: $socialBenevolenceDate, displayedComponents: .date)
                    HStack {
                        Text("Hours")
                        TextField("0", text: $socialBenevolenceHoursText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Save hours", action: saveBenevolenceHours)
                        .disabled(socialBenevolenceHoursText.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadBenevolenceHours() }
            .onChange(of: socialBenevolenceDate) { _, _ in loadBenevolenceHours() }
        }
    }

    private func loadBenevolenceHours() {
        let hours = StorageService.shared.getSocialBenevolenceHours(dateKey: dateKey)
        socialBenevolenceHoursText = hours > 0 ? (hours == Double(Int(hours)) ? "\(Int(hours))" : "\(hours)") : ""
    }

    private func saveBenevolenceHours() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let hours = Double(socialBenevolenceHoursText.replacingOccurrences(of: ",", with: ".")) ?? 0
        StorageService.shared.setSocialBenevolenceHours(dateKey: dateKey, hours: max(0, hours))
    }
}
