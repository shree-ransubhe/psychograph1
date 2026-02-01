import SwiftUI

/// First-launch login: AKSK = username, Email = password. Validated against DefaultProfile.plist in bundle.
struct LoginView: View {
    var onSuccess: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isSubmitting: Bool = false

    private let storage = StorageService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingL) {
                Spacer(minLength: AppTheme.spacingXL)

                Text("PsychoGraph")
                    .font(AppTheme.largeTitle())
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Use your AKSK as username and Email as password")
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("Username (AKSK)")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("AKSK", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _, _ in
                            errorMessage = nil
                        }
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingS) {
                    Text("Password (Email)")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Email", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: password) { _, _ in
                            errorMessage = nil
                        }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(AppTheme.caption())
                        .foregroundStyle(.red)
                }

                PrimaryButton(title: isSubmitting ? "Checking…" : "Log in", action: submit, fullWidth: true)
                    .disabled(isSubmitting || username.isEmpty || password.isEmpty)

                Spacer(minLength: AppTheme.spacingXL)
            }
            .padding(AppTheme.spacingL)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        if storage.validateAndLogin(username: username, password: password) {
            onSuccess()
        } else {
            FailureLogger.shared.logFailure(context: "Login", message: "Invalid credentials (no match in bundle)")
            errorMessage = "Username or password does not match. Please try again."
        }
    }
}

#Preview("Login") {
    LoginView(onSuccess: {})
}
