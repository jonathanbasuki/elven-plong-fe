import Foundation

public enum StaffAvailability: String, Codable, CaseIterable, Sendable {
    case available = "Available"
    case busy = "Busy"
    case offline = "Offline"
}

public struct SecurityStaff: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var currentZoneID: UUID?
    public var availabilityStatus: StaffAvailability
    public var activeAssignmentID: UUID?
    public var mockDistancesToZones: [UUID: Double]
    
    public init(
        id: UUID = UUID(),
        name: String,
        currentZoneID: UUID? = nil,
        availabilityStatus: StaffAvailability = .available,
        activeAssignmentID: UUID? = nil,
        mockDistancesToZones: [UUID: Double] = [:]
    ) {
        self.id = id
        self.name = name
        self.currentZoneID = currentZoneID
        self.availabilityStatus = availabilityStatus
        self.activeAssignmentID = activeAssignmentID
        self.mockDistancesToZones = mockDistancesToZones
    }
    
    public func distance(to zoneID: UUID) -> Double {
        return mockDistancesToZones[zoneID] ?? 100.0
    }
}
