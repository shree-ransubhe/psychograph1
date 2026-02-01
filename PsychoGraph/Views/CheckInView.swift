import SwiftUI
import UIKit

struct CheckInView: View {
    @Binding var showAddSheet: Bool

    @State private var socialBenevolenceDate = Date()
    @State private var socialBenevolenceHoursText = ""
    @State private var selectedMonthTotal: Double = 0
    @State private var cumulativeTotal: Double = 0
    @State private var savedFeedbackShown = false

    private let calendar = Calendar.current

    /// Canonical date key (yyyy-MM-dd) for the selected date, normalized to start of day so storage is consistent.
    private var dateKey: String {
        let startOfDay = calendar.startOfDay(for: socialBenevolenceDate)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = calendar
        return f.string(from: startOfDay)
    }

    private var selectedMonthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        f.calendar = calendar
        return f.string(from: socialBenevolenceDate)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: { showAddSheet = true }) {
                        HStack {
                            Spacer()
                            Text("Add Today's Graph")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("श्रमानंद तास (Social benevolence hrs)")) {
                    DatePicker("Date", selection: $socialBenevolenceDate, displayedComponents: .date)
                        .onChange(of: socialBenevolenceDate) { _, _ in
                            loadBenevolenceHours()
                            loadTotals()
                        }
                    HStack {
                        Text("Hours")
                        TextField("0", text: $socialBenevolenceHoursText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button(action: saveBenevolenceHours) {
                        HStack {
                            if savedFeedbackShown {
                                Label("Saved", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Save hours")
                            }
                        }
                    }
                    .disabled(socialBenevolenceHoursText.isEmpty)
                    Text("You can log श्रमानंद तास as and when it's done. The system will sum it up for the month. You can also add or edit hours when exporting the monthly report.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(selectedMonthLabel) total: \(formatHours(selectedMonthTotal)) hrs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Cumulative (all time): \(formatHours(cumulativeTotal)) hrs")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadBenevolenceHours()
                loadTotals()
            }
        }
    }

    private func loadBenevolenceHours() {
        let hours = StorageService.shared.getSocialBenevolenceHours(dateKey: dateKey)
        socialBenevolenceHoursText = hours > 0 ? (hours == Double(Int(hours)) ? "\(Int(hours))" : "\(hours)") : ""
    }

    /// Refresh displayed totals from storage so they stay in sync after save or date change.
    private func loadTotals() {
        let year = calendar.component(.year, from: socialBenevolenceDate)
        let month = calendar.component(.month, from: socialBenevolenceDate)
        selectedMonthTotal = StorageService.shared.getMonthTotalSocialBenevolence(year: year, month: month)
        cumulativeTotal = StorageService.shared.getCumulativeSocialBenevolence()
    }

    private func saveBenevolenceHours() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let hours = Double(socialBenevolenceHoursText.replacingOccurrences(of: ",", with: ".")) ?? 0
        StorageService.shared.setSocialBenevolenceHours(dateKey: dateKey, hours: max(0, hours))
        loadTotals()
        savedFeedbackShown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedFeedbackShown = false
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours == Double(Int(hours)) {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}
