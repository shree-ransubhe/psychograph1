import SwiftUI

private let adminEmail = "shree@manashakti.org"

struct ProfileView: View {
    private let storage = StorageService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var mobile: String = ""
    @State private var pan: String = ""
    @State private var address: String = ""
    @State private var kendra: String = ""
    @State private var showSaveConfirmation = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        List {
            profileSection
            contactAdminSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear(perform: loadProfile)
        .alert("Profile Saved", isPresented: $showSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been saved.")
        }
        .alert("Log out?", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log out", role: .destructive) {
                storage.logout()
            }
        } message: {
            Text("You will need to log in again.")
        }
    }

    private var profileSection: some View {
        Section {
            TextField("Name", text: $name)
                .textContentType(.name)
                .autocapitalization(.words)

            TextField("Mobile number", text: $mobile)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

            TextField("PAN Number", text: $pan)
                .textContentType(.none)
                .autocapitalization(.allCharacters)

            TextField("Address", text: $address)
                .textContentType(.fullStreetAddress)
                .autocapitalization(.words)

            TextField("Kendra", text: $kendra)
                .textContentType(.none)
                .autocapitalization(.words)

            HStack {
                Text("Email ID")
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(storage.profileEmail.isEmpty ? "—" : storage.profileEmail)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            HStack {
                Text("AKSK number")
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(storage.profileAKSK.isEmpty ? "—" : storage.profileAKSK)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }
        } header: {
            Text("Profile")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("Email ID and AKSK number are provided by the admin (invite-only app). They are set from the backend and cannot be changed. For any requests, use Contact Admin below.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var contactAdminSection: some View {
        Section {
            Button {
                openMailToAdmin()
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(AppTheme.primary)
                    Text("Email admin for requests")
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        } header: {
            Text("Contact Admin")
                .font(AppTheme.sectionHeader())
                .foregroundStyle(AppTheme.textSecondary)
        } footer: {
            Text("Send an email to \(adminEmail) for support or any requests.")
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log out")
                }
            }
        }
    }

    private func loadProfile() {
        name = storage.profileName
        mobile = storage.profileMobile
        pan = storage.profilePAN
        address = storage.profileAddress
        kendra = storage.profileKendra
    }

    private func saveProfile() {
        storage.profileName = name
        storage.profileMobile = mobile
        storage.profilePAN = pan
        storage.profileAddress = address
        storage.profileKendra = kendra
        showSaveConfirmation = true
    }

    private func openMailToAdmin() {
        let aksk = storage.profileAKSK
        let subject = aksk.isEmpty
            ? "PsychoGraph – Request"
            : "PsychoGraph – Request – AKSK: \(aksk)"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let urlString = "mailto:\(adminEmail)?subject=\(encodedSubject)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Profile") {
    NavigationStack {
        ProfileView()
    }
}
