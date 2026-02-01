import SwiftUI

enum Tab: Int, CaseIterable {
    case checkIn = 0
    case report = 1
    case settings = 2
}

struct ContentView: View {
    @State private var selectedTab: Tab = .checkIn
    @State private var showAddTodaysGraphSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CheckInView(showAddSheet: $showAddTodaysGraphSheet)
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
                initialDate: Date(),
                onDismiss: { showAddTodaysGraphSheet = false },
                onCompleteAndGoToReport: {
                    showAddTodaysGraphSheet = false
                    selectedTab = .report
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAddTodaysGraph)) { _ in
            selectedTab = .checkIn
            showAddTodaysGraphSheet = true
        }
    }
}
