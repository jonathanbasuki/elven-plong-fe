import Foundation
import Observation

/// Manages persistent session storage for auth tokens and current user profile.
@Observable
@MainActor
public final class AuthSessionManager {
    public static let shared = AuthSessionManager()
    
    private let defaults: UserDefaults
    private let accessTokenKey = "plong.auth.access_token"
    private let refreshTokenKey = "plong.auth.refresh_token"
    private let currentUserKey = "plong.auth.current_user"
    
    public private(set) var accessToken: String?
    public private(set) var refreshToken: String?
    public private(set) var currentUser: UserResponse?
    
    public var isAuthenticated: Bool {
        accessToken != nil && currentUser != nil
    }
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.accessToken = defaults.string(forKey: accessTokenKey)
        self.refreshToken = defaults.string(forKey: refreshTokenKey)
        if let userData = defaults.data(forKey: currentUserKey) {
            self.currentUser = try? JSONDecoder().decode(UserResponse.self, from: userData)
        }
    }
    
    public func saveSession(token: TokenResponse) {
        self.accessToken = token.accessToken
        self.refreshToken = token.refreshToken
        self.currentUser = token.user
        
        defaults.set(token.accessToken, forKey: accessTokenKey)
        defaults.set(token.refreshToken, forKey: refreshTokenKey)
        if let encodedUser = try? JSONEncoder().encode(token.user) {
            defaults.set(encodedUser, forKey: currentUserKey)
        }
    }
    
    public func clearSession() {
        self.accessToken = nil
        self.refreshToken = nil
        self.currentUser = nil
        
        defaults.removeObject(forKey: accessTokenKey)
        defaults.removeObject(forKey: refreshTokenKey)
        defaults.removeObject(forKey: currentUserKey)
    }
}

