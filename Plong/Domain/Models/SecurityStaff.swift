import Foundation

public enum StaffStatus: String, Codable, CaseIterable, Sendable {
    case idle = "idle"
    case delegating = "delegating"
    
    public var label: String {
        switch self {
        case .idle: return "Idle"
        case .delegating: return "Delegating"
        }
    }
}

public enum StaffAvailability: String, Codable, CaseIterable, Sendable {
    case available = "Available"
    case busy = "Busy"
    case offline = "Offline"
}

public struct SecurityStaff: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID // staff_id
    public var name: String
    public var status: StaffStatus
    public var pushToken: String?
    public var currentZoneID: String?
    public var activeAssignmentID: UUID?
    public var mockDistancesToZones: [String: Double]
    
    public var availabilityStatus: StaffAvailability {
        status == .idle ? .available : .busy
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        status: StaffStatus = .idle,
        pushToken: String? = nil,
        currentZoneID: String? = nil,
        activeAssignmentID: UUID? = nil,
        mockDistancesToZones: [String: Double] = [:]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.pushToken = pushToken
        self.currentZoneID = currentZoneID
        self.activeAssignmentID = activeAssignmentID
        self.mockDistancesToZones = mockDistancesToZones
    }
    
    public func distance(to zoneID: String) -> Double {
        return mockDistancesToZones[zoneID] ?? 100.0
    }
}
