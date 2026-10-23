import SwiftUI
import Observation

@Observable
@MainActor
public final class NavigationRouter {
    public var path = NavigationPath()
    public var isAuthenticated: Bool = false
    
    public init(isAuthenticated: Bool = false) {
        self.isAuthenticated = isAuthenticated
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
