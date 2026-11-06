import XCTest
@testable import Plong

@MainActor
final class AuthServiceTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var sessionManager: AuthSessionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        testDefaults = UserDefaults(suiteName: "AuthServiceTestsSuite")!
        testDefaults.removePersistentDomain(forName: "AuthServiceTestsSuite")
        sessionManager = AuthSessionManager(defaults: testDefaults)
    }
    
    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "AuthServiceTestsSuite")
        testDefaults = nil
        sessionManager = nil
        try await super.tearDown()
    }
    
    // 1. Test AuthSessionManager saves and clears tokens
    func test_authSessionManager_saveAndClearSession() {
        XCTAssertFalse(sessionManager.isAuthenticated)
        XCTAssertNil(sessionManager.accessToken)
        XCTAssertNil(sessionManager.currentUser)
        
        let tokenResponse = TokenResponse(
            accessToken: "test-access-token-123",
            refreshToken: "test-refresh-token-456",
            expiresIn: 3600,
            user: UserResponse(
                id: UUID(),
                email: "manager@venue.com",
                fullName: "Rendi Septrian",
                role: "manager",
                isActive: true
            )
        )
        
        sessionManager.saveSession(token: tokenResponse)
        XCTAssertTrue(sessionManager.isAuthenticated)
        XCTAssertEqual(sessionManager.accessToken, "test-access-token-123")
        XCTAssertEqual(sessionManager.refreshToken, "test-refresh-token-456")
        XCTAssertEqual(sessionManager.currentUser?.email, "manager@venue.com")
        XCTAssertEqual(sessionManager.currentUser?.userRole, .manager)
        
        sessionManager.clearSession()
        XCTAssertFalse(sessionManager.isAuthenticated)
        XCTAssertNil(sessionManager.accessToken)
        XCTAssertNil(sessionManager.currentUser)
    }
    
    // 2. Test JSON decoding of Backend TokenResponse matches api.plong.my.id schema
    func test_tokenResponse_decodingFromBackendPayload() throws {
        let json = """
        {
          "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
          "refreshToken": "dGhpcy1pcy1hLXJlZnJlc2gtdG9rZW4...",
          "tokenType": "bearer",
          "expiresIn": 3600,
          "user": {
            "id": "e5b8e9b6-8f2c-4e89-b88d-7a35987116a4",
            "email": "rendi@venue.com",
            "fullName": "Rendi Septrian",
            "role": "ops_manager",
            "isActive": true
          }
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: json)
        XCTAssertEqual(decoded.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
        XCTAssertEqual(decoded.tokenType, "bearer")
        XCTAssertEqual(decoded.expiresIn, 3600)
        XCTAssertEqual(decoded.user.fullName, "Rendi Septrian")
        XCTAssertEqual(decoded.user.role, "ops_manager")
        XCTAssertEqual(decoded.user.userRole, .manager)
        XCTAssertTrue(decoded.user.isActive)
    }
    
    // 3. Test userRole mapping for ops_manager, ops_staff, and fallback heuristics
    func test_userResponse_roleMapping_opsManagerAndStaff() {
        let managerUser = UserResponse(id: UUID(), email: "mgr@venue.com", fullName: "Mgr", role: "ops_manager", isActive: true)
        XCTAssertEqual(managerUser.userRole, .manager)
        
        let staffUser = UserResponse(id: UUID(), email: "stf@venue.com", fullName: "Stf", role: "ops_staff", isActive: true)
        XCTAssertEqual(staffUser.userRole, .staff)
        
        let plainStaff = UserResponse(id: UUID(), email: "user@venue.com", fullName: "Stf2", role: "staff", isActive: true)
        XCTAssertEqual(plainStaff.userRole, .staff)
        
        let plainManager = UserResponse(id: UUID(), email: "user@venue.com", fullName: "Mgr2", role: "manager", isActive: true)
        XCTAssertEqual(plainManager.userRole, .manager)
    }
    
    // 4. Test APIErrorResponse decoding from backend 401 unauthenticated
    func test_apiErrorResponse_decoding() throws {
        let errorJson = """
        {"error":{"code":"unauthenticated","message":"Invalid email or password"}}
        """.data(using: .utf8)!
        
        let errorPayload = try JSONDecoder().decode(APIErrorResponse.self, from: errorJson)
        XCTAssertEqual(errorPayload.error.code, "unauthenticated")
        XCTAssertEqual(errorPayload.error.message, "Invalid email or password")
    }
    
    // 4. Test LoginViewModel handling error from AuthService
    func test_loginViewModel_displaysBackendErrorMessage() async {
        let router = NavigationRouter()
        let mockAuth = MockAuthService(shouldSucceed: false)
        let vm = LoginViewModel(router: router, authService: mockAuth)
        
        vm.email = "test@venue.com"
        vm.password = "wrongpass"
        vm.signIn()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(router.isAuthenticated)
        XCTAssertEqual(vm.generalError, "Invalid email or password")
        XCTAssertFalse(vm.isLoading)
    }
}

