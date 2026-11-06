import Foundation

// MARK: - Auth Request DTOs

/// Request payload for `POST /api/v1/auth/login`.
public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Request payload for `POST /api/v1/auth/refresh` and `POST /api/v1/auth/logout`.
public struct RefreshRequest: Codable, Sendable {
    public let refreshToken: String
    
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

// MARK: - Auth Response DTOs

/// User information returned inside `TokenResponse` and from `GET /api/v1/profile`.
public struct UserResponse: Codable, Sendable, Identifiable {
    public let id: UUID
    public let email: String
    public let fullName: String
    public let role: String
    public let isActive: Bool
    
    public init(
        id: UUID,
        email: String,
        fullName: String,
        role: String,
        isActive: Bool
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.role = role
        self.isActive = isActive
    }
    
    /// Maps backend string role ("manager" | "staff") to frontend UserRole enum
    public var userRole: UserRole {
        role.lowercased() == "staff" ? .staff : .manager
    }
}

/// Token response returned from `POST /api/v1/auth/login` and `POST /api/v1/auth/refresh`.
public struct TokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let user: UserResponse
    
    public init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "bearer",
        expiresIn: Int,
        user: UserResponse
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.user = user
    }
}

// MARK: - API Error DTOs

/// Structured error payload returned by Plong backend (e.g. `{"error":{"code":"unauthenticated","message":"..."}}`).
public struct APIErrorResponse: Codable, Sendable {
    public let error: APIErrorDetail
}

public struct APIErrorDetail: Codable, Sendable {
    public let code: String
    public let message: String
}

/// Unified error type thrown by networking calls.
public enum APIError: LocalizedError, Sendable {
    case invalidURL
    case network(String)
    case server(code: String, message: String, statusCode: Int)
    case unauthenticated(String)
    case decoding(String)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .network(let message):
            return message
        case .server(_, let message, _):
            return message
        case .unauthenticated(let message):
            return message
        case .decoding(let detail):
            return "Failed to decode response: \(detail)"
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}

