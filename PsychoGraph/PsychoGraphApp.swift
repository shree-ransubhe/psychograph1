import SwiftUI

@main
struct PsychoGraphApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isAuthenticated = StorageService.shared.isAuthenticated

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    ContentView()
                } else {
                    LoginView(onSuccess: { isAuthenticated = true })
                }
            }
            .onAppear {
                StorageService.shared.clearReportDataOnceIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                isAuthenticated = false
            }
        }
    }
}
