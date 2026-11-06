import Foundation

/// Central configuration for API environments and backend connectivity.
public enum AppConfig {
    /// Base URL for the Plong Elven Backend API
    public static var baseURL: URL = URL(string: "https://api.plong.my.id")!
    
    /// Default network request timeout in seconds
    public static let requestTimeout: TimeInterval = 15.0
}

