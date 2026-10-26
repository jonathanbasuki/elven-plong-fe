import Foundation

public enum ZoneStatus: String, Codable, CaseIterable, Sendable {
    case safe = "safe"
    case warning = "warning"
    case crowded = "crowded"
    
    public var label: String {
        switch self {
        case .safe: return "Safe"
        case .warning: return "Warning"
        case .crowded: return "Crowded"
        }
    }
}

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
    public let id: String // zone_id, matches camera_id in elven-plong-be (e.g. "z1")
    public var name: String
    public var currentCount: Int
    public var warningThreshold: Int
    public var crowdedThreshold: Int
    public var mapImageUrl: String
    public var polygon: [[Double]] // [[x, y], ...] normalized 0..1
    public var assignedStaffIDs: [UUID]
    
    public var status: ZoneStatus {
        if currentCount < warningThreshold {
            return .safe
        } else if currentCount < crowdedThreshold {
            return .warning
        } else {
            return .crowded
        }
    }
    
    // Backwards compatibility helpers
    public var crowdCount: Int {
        get { currentCount }
        set { currentCount = newValue }
    }
    
    public var crowdSeverity: CrowdSeverity {
        switch status {
        case .safe: return .low
        case .warning: return .moderate
        case .crowded: return .high
        }
    }
    
    public var requiredAdditionalSecurity: Int {
        switch status {
        case .safe: return 0
        case .warning: return 2
        case .crowded: return 4
        }
    }
    
    public init(
        id: String,
        name: String,
        currentCount: Int = 0,
        warningThreshold: Int = 5,
        crowdedThreshold: Int = 10,
        mapImageUrl: String = "",
        polygon: [[Double]] = [],
        assignedStaffIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.currentCount = currentCount
        self.warningThreshold = warningThreshold
        self.crowdedThreshold = crowdedThreshold
        self.mapImageUrl = mapImageUrl
        self.polygon = polygon
        self.assignedStaffIDs = assignedStaffIDs
    }
}
