import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: Session
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Plong").font(.largeTitle.bold())
                Text("Sign in to continue").foregroundStyle(.secondary)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                TextField("Email", text: $email)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textContentType(.password)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                PrimaryButton(title: isLoading ? "Signing in..." : "Log in", action: logIn)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .scrollDisabled(true)
    }

    private func logIn() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                let result = try await API.login(email: email, password: password)
                let zones = try await API.listZones(token: result.accessToken)
                guard let zoneId = zones.first?.zoneId else {
                    errorMessage = "No zone is configured on the server yet"
                    isLoading = false
                    return
                }
                session.startSession(accessToken: result.accessToken, refreshToken: result.refreshToken, user: result.user)
                session.zoneId = zoneId
                PushNotifications.requestPermission()
            } catch {
                errorMessage = (error as? APIError)?.message ?? "Could not sign in"
            }
            isLoading = false
        }
    }
}
