import SwiftUI
import Observation

public enum UserRole: String, Codable, CaseIterable, Sendable {
    case manager = "Manager"
    case staff = "Staff"
}

@Observable
@MainActor
public final class NavigationRouter {
    public var path = NavigationPath()
    public var isAuthenticated: Bool = false
    public var currentUserRole: UserRole = .manager
    
    public init(isAuthenticated: Bool = false, currentUserRole: UserRole = .manager) {
        self.isAuthenticated = isAuthenticated
        self.currentUserRole = currentUserRole
    }
    
    public func login(as role: UserRole) {
        self.currentUserRole = role
        self.isAuthenticated = true
        self.path = NavigationPath()
    }
    
    public func logout() {
        self.isAuthenticated = false
        self.path = NavigationPath()
        Task {
            try? await AuthService.shared.logout()
        }
    }
    
    public func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    public func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    public func popToRoot() {
        path = NavigationPath()
    }
}
