import Foundation

public enum CrowdSeverity: String, Codable, CaseIterable, Sendable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
    
    public var label: String {
        return rawValue
    }
}

public struct VenueZone: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var crowdCount: Int
    public var crowdSeverity: CrowdSeverity
    public var assignedStaffIDs: [UUID]
    public var requiredAdditionalSecurity: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        crowdCount: Int,
        crowdSeverity: CrowdSeverity,
        assignedStaffIDs: [UUID] = [],
        requiredAdditionalSecurity: Int = 0
    ) {
        self.id = id
        self.name = name
        self.crowdCount = crowdCount
        self.crowdSeverity = crowdSeverity
        self.assignedStaffIDs = assignedStaffIDs
        self.requiredAdditionalSecurity = requiredAdditionalSecurity
    }
}
