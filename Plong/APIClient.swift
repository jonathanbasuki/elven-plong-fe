import Combine
import Foundation

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
    /// Single-zone POC: both roles watch this one zone.
    static let zoneId = "z2"

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

    static func getZone(token: String) async throws -> ZoneStat {
        try await get("/api/v1/dispatch/zones/\(zoneId)", token: token)
    }

    /// nil when no broadcast has ever been created for this zone (server 404s).
    static func getCurrentBroadcast(token: String) async throws -> BroadcastState? {
        do {
            return try await get(
                "/api/v1/dispatch/broadcasts/current?zoneId=\(zoneId)", token: token
            )
        } catch let error as APIError where error.code == "not_found" {
            return nil
        }
    }

    private struct CreateBroadcastBody: Encodable { let zoneId: String; let staffNeeded: Int }
    static func createBroadcast(staffNeeded: Int, token: String) async throws -> BroadcastState {
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

    var isManager: Bool { user?.role == "ops_manager" }

    func logOut() {
        accessToken = nil
        user = nil
    }
}
