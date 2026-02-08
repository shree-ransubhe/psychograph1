import SwiftUI

enum Tab: Int, CaseIterable {
    case checkIn = 0
    case report = 1
    case settings = 2
}

struct ContentView: View {
    @State private var selectedTab: Tab = .checkIn
    @State private var showAddTodaysGraphSheet = false
    @State private var sheetInitialDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var benevolencePromptDate: Date?
    @State private var benevolencePromptDateString: String = ""
    @State private var pendingBenevolenceDate: Date?

    var body: some View {
        TabView(selection: $selectedTab) {
            CheckInView(showAddSheet: $showAddTodaysGraphSheet, sheetInitialDate: $sheetInitialDate, pendingBenevolenceDate: $pendingBenevolenceDate)
                .tabItem { Label("Check-in", systemImage: "checkmark.circle") }
                .tag(Tab.checkIn)

            GraphView()
                .tabItem { Label("Report", systemImage: "doc.text") }
                .tag(Tab.report)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddTodaysGraphSheet) {
            AddTodaysGraphView(
                initialDate: sheetInitialDate,
                onDismiss: { showAddTodaysGraphSheet = false },
                onCompleteAndGoToReport: { loggedDate in
                    showAddTodaysGraphSheet = false
                    benevolencePromptDate = loggedDate
                    let f = DateFormatter()
                    f.dateStyle = .medium
                    benevolencePromptDateString = f.string(from: loggedDate)
                }
            )
        }
        .alert("Log श्रमानंद तास?", isPresented: Binding(
            get: { benevolencePromptDate != nil },
            set: { if !$0 { benevolencePromptDate = nil } }
        )) {
            Button("Log hours") {
                if let d = benevolencePromptDate {
                    pendingBenevolenceDate = d
                    selectedTab = .checkIn
                }
                benevolencePromptDate = nil
            }
            Button("I'll add later", role: .cancel) {
                selectedTab = .report
                benevolencePromptDate = nil
            }
        } message: {
            Text("Would you like to log श्रमानंद तास for \(benevolencePromptDateString)? You can also add or edit hours when exporting the monthly report.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAddTodaysGraph)) { _ in
            selectedTab = .checkIn
            sheetInitialDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            showAddTodaysGraphSheet = true
        }
    }
}
