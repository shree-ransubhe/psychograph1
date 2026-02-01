import SwiftUI

/// Read-only view of the failure/debug log. Users can export via Settings → Export failure log.
struct FailureLogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var logContent: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if logContent.isEmpty {
                    Text("No failure log yet.")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(logContent)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .textSelection(.enabled)
                }
            }
            .navigationTitle("Failure log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .onAppear {
                logContent = FailureLogger.shared.readLogContent()
            }
        }
    }
}

#Preview("FailureLogView") {
    FailureLogView()
}
