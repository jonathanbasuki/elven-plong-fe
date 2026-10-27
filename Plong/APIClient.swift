import Combine
import Foundation
import UIKit

/// Same LAN as the RTSP camera. Update if the Mac's IP changes.
let apiBaseURL = "http://192.168.2.1:8080"

/// MediaMTX HLS preview (see docs/SETUP_HLS.md) — same Mac, different port, no auth.
let hlsURL = URL(string: "http://192.168.2.1:8888/cam1/index.m3u8")!

struct APIError: Error, LocalizedError {
    let code: String
    let message: String
    var errorDescription: String? { message }
}

private struct APIErrorBody: Decodable {
    struct Detail: Decodable { let code: String; let message: String }
    let error: Detail
}

struct LoggedInUser: Decodable, Equatable {
    let id: String
    let email: String
    let fullName: String
    let role: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: LoggedInUser
}

struct ZoneStat: Decodable {
    let zoneId: String
    let name: String
    let currentCount: Int
    let status: String
}

struct AcceptedStaff: Decodable, Identifiable {
    let staffId: String
    let name: String
    let completedAt: String?
    var id: String { staffId }
}

struct BroadcastState: Decodable {
    let broadcastId: String
    let zoneId: String
    let status: String
    let staffNeeded: Int
    let expiresAt: String
    let acceptedCount: Int
    let completedCount: Int
    let acceptedStaff: [AcceptedStaff]
}

private struct StatusOnly: Decodable { let status: String }
private struct Empty: Encodable {}

enum ISO8601 {
    private static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain = ISO8601DateFormatter()

    static func parse(_ s: String) -> Date {
        withFractional.date(from: s) ?? plain.date(from: s) ?? Date()
    }
}

enum API {
    private static func send<Body: Encodable, Res: Decodable>(
        _ path: String, method: String, body: Body?, token: String?
    ) async throws -> Res {
        var request = URLRequest(url: URL(string: apiBaseURL + path)!)
        request.httpMethod = method
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(code: "network", message: "No response from server")
        }
        guard (200..<300).contains(http.statusCode) else {
            if let parsed = try? decoder.decode(APIErrorBody.self, from: data) {
                throw APIError(code: parsed.error.code, message: parsed.error.message)
            }
            throw APIError(code: "http_\(http.statusCode)", message: "Request failed")
        }
        return try decoder.decode(Res.self, from: data)
    }

    // The auth endpoints return snake_case (access_token, full_name, ...); the dispatch
    // endpoints already return camelCase, which has no underscores so this is a no-op
    // for them. One shared decoder handles both.
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private static func get<Res: Decodable>(_ path: String, token: String) async throws -> Res {
        try await send(path, method: "GET", body: Optional<Empty>.none, token: token)
    }

    private static func post<Res: Decodable>(_ path: String, token: String) async throws -> Res {
        try await send(path, method: "POST", body: Optional<Empty>.none, token: token)
    }

    private struct LoginBody: Encodable { let email: String; let password: String }
    static func login(email: String, password: String) async throws -> LoginResponse {
        try await send(
            "/api/v1/auth/login", method: "POST",
            body: LoginBody(email: email, password: password), token: nil
        )
    }

    private struct RefreshBody: Encodable {
        let refreshToken: String
        enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
    }
    struct RefreshResponse: Decodable {
        let accessToken: String
        let refreshToken: String
    }
    /// The access token expires after 15 minutes (ACCESS_TOKEN_MINUTES); Session calls
    /// this proactively on a timer so a long-running shift never hits a stream of 401s.
    static func refresh(refreshToken: String) async throws -> RefreshResponse {
        try await send(
            "/api/v1/auth/refresh", method: "POST",
            body: RefreshBody(refreshToken: refreshToken), token: nil
        )
    }

    /// Revokes the refresh token and clears the device's push token server-side —
    /// otherwise this device keeps getting pushes for the account after signing out.
    static func logout(refreshToken: String) async throws {
        let _: StatusOnly = try await send(
            "/api/v1/auth/logout", method: "POST",
            body: RefreshBody(refreshToken: refreshToken), token: nil
        )
    }

    /// /auth/refresh only returns a token pair, not the user — this fills in `user`
    /// when silently restoring a session from a saved refresh token at launch.
    static func profile(token: String) async throws -> LoggedInUser {
        try await get("/api/v1/auth/profile", token: token)
    }

    /// Single-zone POC: no zone picker, so the app just discovers whichever zone the
    /// server returns first rather than hardcoding an id that can drift out of sync
    /// with zones.json (the cctv worker's own source of zone ids).
    static func listZones(token: String) async throws -> [ZoneStat] {
        try await get("/api/v1/dispatch/zones", token: token)
    }

    static func getZone(zoneId: String, token: String) async throws -> ZoneStat {
        try await get("/api/v1/dispatch/zones/\(zoneId)", token: token)
    }

    /// nil when no broadcast has ever been created for this zone (server 404s).
    static func getCurrentBroadcast(zoneId: String, token: String) async throws -> BroadcastState? {
        do {
            return try await get(
                "/api/v1/dispatch/broadcasts/current?zoneId=\(zoneId)", token: token
            )
        } catch let error as APIError where error.code == "not_found" {
            return nil
        }
    }

    private struct CreateBroadcastBody: Encodable { let zoneId: String; let staffNeeded: Int }
    static func createBroadcast(zoneId: String, staffNeeded: Int, token: String) async throws -> BroadcastState {
        try await send(
            "/api/v1/dispatch/broadcasts", method: "POST",
            body: CreateBroadcastBody(zoneId: zoneId, staffNeeded: staffNeeded), token: token
        )
    }

    static func respond(broadcastId: String, token: String) async throws {
        let _: StatusOnly = try await post(
            "/api/v1/dispatch/broadcasts/\(broadcastId)/respond", token: token
        )
    }

    static func complete(broadcastId: String, token: String) async throws {
        let _: StatusOnly = try await post(
            "/api/v1/dispatch/broadcasts/\(broadcastId)/complete", token: token
        )
    }

    private struct PushTokenBody: Encodable { let pushToken: String }
    static func registerPushToken(_ pushToken: String, token: String) async throws {
        let _: StatusOnly = try await send(
            "/api/v1/auth/push-token", method: "POST",
            body: PushTokenBody(pushToken: pushToken), token: token
        )
    }

    static func finish(broadcastId: String, token: String) async throws {
        let _: StatusOnly = try await post(
            "/api/v1/dispatch/broadcasts/\(broadcastId)/finish", token: token
        )
    }
}

@MainActor
final class Session: ObservableObject {
    @Published var accessToken: String?
    @Published var user: LoggedInUser?
    @Published var zoneId: String?
    // Starts true so ContentView can show a loading state instead of flashing the
    // login screen for an instant while restoreSession() checks the Keychain.
    @Published var isRestoringSession = true
    private var refreshToken: String?
    private var refreshTask: Task<Void, Never>?
    private static let refreshTokenKey = "refreshToken"

    var isManager: Bool { user?.role == "ops_manager" }

    func startSession(accessToken: String, refreshToken: String, user: LoggedInUser) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
        Keychain.save(refreshToken, for: Self.refreshTokenKey)
        scheduleAutoRefresh()
    }

    /// Called once at launch: if a refresh token was saved from a previous session,
    /// silently exchanges it for a fresh session instead of forcing a login screen
    /// every time the app is closed and reopened.
    func restoreSession() async {
        defer { isRestoringSession = false }
        guard let savedRefreshToken = Keychain.load(Self.refreshTokenKey) else { return }
        do {
            let tokens = try await API.refresh(refreshToken: savedRefreshToken)
            let user = try await API.profile(token: tokens.accessToken)
            let zones = try await API.listZones(token: tokens.accessToken)
            startSession(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: user)
            zoneId = zones.first?.zoneId
            PushNotifications.requestPermission()
        } catch {
            // Saved token is invalid/expired/revoked — fall through to a normal login.
            Keychain.delete(Self.refreshTokenKey)
        }
    }

    // The access token expires after 15 minutes server-side; refresh at a comfortable
    // margin before that so a manager/staff member mid-shift never sees a stream of
    // silent 401s instead of live data.
    private func scheduleAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10 * 60))
                guard let self, let refreshToken = self.refreshToken else { return }
                do {
                    let result = try await API.refresh(refreshToken: refreshToken)
                    self.accessToken = result.accessToken
                    self.refreshToken = result.refreshToken
                    Keychain.save(result.refreshToken, for: Self.refreshTokenKey)
                } catch {
                    self.logOut()
                    return
                }
            }
        }
    }

    func logOut() {
        refreshTask?.cancel()
        refreshTask = nil
        let tokenToRevoke = refreshToken
        accessToken = nil
        refreshToken = nil
        user = nil
        zoneId = nil
        Keychain.delete(Self.refreshTokenKey)
        // Stops this device from being reachable for future pushes immediately,
        // client-side, in addition to the server clearing push_token below.
        UIApplication.shared.unregisterForRemoteNotifications()
        if let tokenToRevoke {
            Task { try? await API.logout(refreshToken: tokenToRevoke) }
        }
    }
}
