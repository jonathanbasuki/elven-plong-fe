import Foundation

/// Protocol abstracting authentication network requests.
@MainActor
public protocol AuthServiceProtocol: AnyObject, Sendable {
    func login(request: LoginRequest) async throws -> TokenResponse
    func logout() async throws
}

/// Production implementation of `AuthServiceProtocol` connecting to `https://api.plong.my.id`.
@MainActor
public final class AuthService: AuthServiceProtocol {
    public static let shared = AuthService()
    
    private let baseURL: URL
    private let urlSession: URLSession
    private let sessionManager: AuthSessionManager
    
    public init(
        baseURL: URL = AppConfig.baseURL,
        urlSession: URLSession = .shared,
        sessionManager: AuthSessionManager = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.sessionManager = sessionManager
    }
    
    // MARK: - Login
    public func login(request: LoginRequest) async throws -> TokenResponse {
        let endpoint = baseURL.appendingPathComponent("api/v1/auth/login")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = AppConfig.requestTimeout
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.decoding("Failed to encode login request.")
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.network("Network error: \(error.localizedDescription)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidURL
        }
        
        // Handle successful 200 OK
        if (200...299).contains(httpResponse.statusCode) {
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                sessionManager.saveSession(token: tokenResponse)
                return tokenResponse
            } catch {
                throw APIError.decoding(error.localizedDescription)
            }
        }
        
        // Handle server error responses (e.g. 401 unauthenticated, 422 validation)
        if let errorPayload = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthenticated(errorPayload.error.message)
            } else {
                throw APIError.server(
                    code: errorPayload.error.code,
                    message: errorPayload.error.message,
                    statusCode: httpResponse.statusCode
                )
            }
        }
        
        throw APIError.server(
            code: "http_\(httpResponse.statusCode)",
            message: "Server returned error (\(httpResponse.statusCode)).",
            statusCode: httpResponse.statusCode
        )
    }
    
    // MARK: - Logout
    public func logout() async throws {
        let refreshToken = sessionManager.refreshToken
        
        // Invalidate session on server if refresh token is present
        if let refreshToken = refreshToken, !refreshToken.isEmpty {
            let endpoint = baseURL.appendingPathComponent("api/v1/auth/logout")
            var urlRequest = URLRequest(url: endpoint)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = AppConfig.requestTimeout
            
            let refreshPayload = RefreshRequest(refreshToken: refreshToken)
            if let body = try? JSONEncoder().encode(refreshPayload) {
                urlRequest.httpBody = body
                _ = try? await urlSession.data(for: urlRequest)
            }
        }
        
        // Clear local storage
        sessionManager.clearSession()
    }
}

/// Mock implementation of `AuthServiceProtocol` for unit testing and offline previews.
@MainActor
public final class MockAuthService: AuthServiceProtocol {
    public var shouldSucceed: Bool
    public var simulatedError: APIError?
    
    public init(shouldSucceed: Bool = true, simulatedError: APIError? = nil) {
        self.shouldSucceed = shouldSucceed
        self.simulatedError = simulatedError
    }
    
    public func login(request: LoginRequest) async throws -> TokenResponse {
        if let error = simulatedError {
            throw error
        }
        if !shouldSucceed {
            throw APIError.unauthenticated("Invalid email or password")
        }
        let role = request.email.lowercased().contains("staff") ? "staff" : "manager"
        return TokenResponse(
            accessToken: "mock-jwt-access-token",
            refreshToken: "mock-jwt-refresh-token",
            expiresIn: 3600,
            user: UserResponse(
                id: UUID(),
                email: request.email,
                fullName: role == "staff" ? "Staff Officer" : "Venue Manager",
                role: role,
                isActive: true
            )
        )
    }
    
    public func logout() async throws {}
}
