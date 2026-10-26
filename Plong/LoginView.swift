import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: Session
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Plong").font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Sign in to continue").foregroundStyle(.secondary)

            TextField("Email", text: $email)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }

            PrimaryButton(title: isLoading ? "Signing in..." : "Log in", action: logIn)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .padding(24)
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
                session.accessToken = result.accessToken
                session.user = result.user
                session.zoneId = zoneId
            } catch {
                errorMessage = (error as? APIError)?.message ?? "Could not sign in"
            }
            isLoading = false
        }
    }
}
