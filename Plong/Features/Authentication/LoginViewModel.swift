import Foundation
import Observation

@Observable
@MainActor
public final class LoginViewModel {
    public var email: String = "manager@venue.com"
    public var password: String = "••••••••"
    public var emailError: String? = nil
    public var passwordError: String? = nil
    public var isLoading: Bool = false
    public var generalError: String? = nil
    
    private let router: NavigationRouter
    public let authService: AuthServiceProtocol
    
    public init(
        router: NavigationRouter,
        authService: AuthServiceProtocol = AuthService.shared
    ) {
        self.router = router
        self.authService = authService
    }
    
    public func validate() -> Bool {
        var isValid = true
        emailError = nil
        passwordError = nil
        generalError = nil
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            emailError = "Email is required."
            isValid = false
        } else if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            emailError = "Please enter a valid email address."
            isValid = false
        }
        
        if password.isEmpty {
            passwordError = "Password is required."
            isValid = false
        } else if password.count < 4 {
            passwordError = "Password must be at least 4 characters."
            isValid = false
        }
        
        return isValid
    }
    
    public func signIn() {
        guard validate() else { return }
        
        isLoading = true
        generalError = nil
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = LoginRequest(email: trimmedEmail, password: password)
        
        Task { @MainActor in
            do {
                let tokenResponse = try await authService.login(request: request)
                self.isLoading = false
                let role = tokenResponse.user.userRole
                self.router.login(as: role)
            } catch let apiError as APIError {
                self.isLoading = false
                self.generalError = apiError.localizedDescription
            } catch {
                self.isLoading = false
                self.generalError = error.localizedDescription
            }
        }
    }
}
