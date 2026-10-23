import Foundation
import Observation

@Observable
@MainActor
public final class LoginViewModel {
    public var email: String = ""
    public var password: String = ""
    public var emailError: String? = nil
    public var passwordError: String? = nil
    public var isLoading: Bool = false
    public var generalError: String? = nil
    
    private let router: NavigationRouter
    
    public init(router: NavigationRouter) {
        self.router = router
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
        
        // Simulate brief loading state asynchronously
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s brief simulation
            self.isLoading = false
            self.router.isAuthenticated = true
        }
    }
}
