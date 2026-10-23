import Foundation
import Observation

public struct MockDataConstants {
    public static let zoneAId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    public static let zoneBId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    public static let zoneCId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    public static let zoneDId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    
    public static let staffMarcusId = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    public static let staffSarahId = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    public static let staffAlexId = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    public static let staffDavidId = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    public static let staffElenaId = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
}

@Observable
@MainActor
public final class MockCrowdFlowRepository: CrowdFlowRepositoryProtocol {
    public var zones: [VenueZone] = []
    public var staffMembers: [SecurityStaff] = []
    public var alerts: [CrowdAlert] = []
    public var assignmentRequests: [AssignmentRequest] = []
    public var confirmedAssignments: [ConfirmedAssignment] = []
    
    public init() {
        resetToDefaults()
    }
    
    public func resetToDefaults() {
        let initialStaff1 = SecurityStaff(
            id: MockDataConstants.staffMarcusId,
            name: "Officer Marcus Cole",
            currentZoneID: MockDataConstants.zoneAId,
            availabilityStatus: .available,
            activeAssignmentID: nil,
            mockDistancesToZones: [
                MockDataConstants.zoneAId: 5.0,
                MockDataConstants.zoneBId: 15.0,
                MockDataConstants.zoneCId: 30.0,
                MockDataConstants.zoneDId: 50.0
            ]
        )
        
        let initialStaff2 = SecurityStaff(
            id: MockDataConstants.staffSarahId,
            name: "Officer Sarah Jenkins",
            currentZoneID: MockDataConstants.zoneCId,
            availabilityStatus: .available,
            activeAssignmentID: nil,
            mockDistancesToZones: [
                MockDataConstants.zoneAId: 40.0,
                MockDataConstants.zoneBId: 28.0,
                MockDataConstants.zoneCId: 10.0,
                MockDataConstants.zoneDId: 35.0
            ]
        )
        
        let initialStaff3 = SecurityStaff(
            id: MockDataConstants.staffAlexId,
            name: "Officer Alex Rivera",
            currentZoneID: MockDataConstants.zoneDId,
            availabilityStatus: .available,
            activeAssignmentID: nil,
            mockDistancesToZones: [
                MockDataConstants.zoneAId: 55.0,
                MockDataConstants.zoneBId: 45.0,
                MockDataConstants.zoneCId: 25.0,
                MockDataConstants.zoneDId: 8.0
            ]
        )
        
        let initialStaff4 = SecurityStaff(
            id: MockDataConstants.staffDavidId,
            name: "Officer David Kim",
            currentZoneID: MockDataConstants.zoneAId,
            availabilityStatus: .busy,
            activeAssignmentID: UUID(uuidString: "99999999-9999-9999-9999-999999999999"),
            mockDistancesToZones: [
                MockDataConstants.zoneAId: 2.0,
                MockDataConstants.zoneBId: 12.0,
                MockDataConstants.zoneCId: 28.0,
                MockDataConstants.zoneDId: 48.0
            ]
        )
        
        let initialStaff5 = SecurityStaff(
            id: MockDataConstants.staffElenaId,
            name: "Officer Elena Vance",
            currentZoneID: MockDataConstants.zoneCId,
            availabilityStatus: .offline,
            activeAssignmentID: nil,
            mockDistancesToZones: [
                MockDataConstants.zoneAId: 35.0,
                MockDataConstants.zoneBId: 20.0,
                MockDataConstants.zoneCId: 5.0,
                MockDataConstants.zoneDId: 40.0
            ]
        )
        
        self.staffMembers = [
            initialStaff1,
            initialStaff2,
            initialStaff3,
            initialStaff4,
            initialStaff5
        ]
        
        self.zones = [
            VenueZone(
                id: MockDataConstants.zoneAId,
                name: "Zone A - Main Concourse",
                crowdCount: 250,
                crowdSeverity: .low,
                assignedStaffIDs: [],
                requiredAdditionalSecurity: 0
            ),
            VenueZone(
                id: MockDataConstants.zoneBId,
                name: "Zone B - West Plaza",
                crowdCount: 820,
                crowdSeverity: .high,
                assignedStaffIDs: [],
                requiredAdditionalSecurity: 2
            ),
            VenueZone(
                id: MockDataConstants.zoneCId,
                name: "Zone C - North Gallery",
                crowdCount: 460,
                crowdSeverity: .moderate,
                assignedStaffIDs: [],
                requiredAdditionalSecurity: 1
            ),
            VenueZone(
                id: MockDataConstants.zoneDId,
                name: "Zone D - South Pavilion",
                crowdCount: 180,
                crowdSeverity: .low,
                assignedStaffIDs: [],
                requiredAdditionalSecurity: 0
            )
        ]
        
        self.alerts = [
            CrowdAlert(
                id: UUID(),
                zoneID: MockDataConstants.zoneBId,
                alertType: .highCrowdDetected,
                title: "High Crowd Density",
                message: "Zone B reached 820 occupants exceeding safe threshold. Additional security recommended.",
                createdAt: Date().addingTimeInterval(-300),
                isRead: false
            ),
            CrowdAlert(
                id: UUID(),
                zoneID: MockDataConstants.zoneCId,
                alertType: .crowdDensityIncreasing,
                title: "Density Surge",
                message: "Zone C is showing a rapid inflow of visitors. Monitoring required.",
                createdAt: Date().addingTimeInterval(-120),
                isRead: false
            )
        ]
        
        self.assignmentRequests = []
        self.confirmedAssignments = []
    }
    
    public func getZone(by id: UUID) -> VenueZone? {
        zones.first { $0.id == id }
    }
    
    public func getStaff(by id: UUID) -> SecurityStaff? {
        staffMembers.first { $0.id == id }
    }
    
    public func getAssignmentRequest(by id: UUID) -> AssignmentRequest? {
        assignmentRequests.first { $0.id == id }
    }
    
    public func getConfirmedAssignment(by requestID: UUID) -> ConfirmedAssignment? {
        confirmedAssignments.first { $0.requestID == requestID }
    }
    
    public func updateZone(_ zone: VenueZone) {
        if let index = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[index] = zone
        } else {
            zones.append(zone)
        }
    }
    
    public func updateStaff(_ staff: SecurityStaff) {
        if let index = staffMembers.firstIndex(where: { $0.id == staff.id }) {
            staffMembers[index] = staff
        } else {
            staffMembers.append(staff)
        }
    }
    
    public func addAssignmentRequest(_ request: AssignmentRequest) {
        assignmentRequests.append(request)
    }
    
    public func updateAssignmentRequest(_ request: AssignmentRequest) {
        if let index = assignmentRequests.firstIndex(where: { $0.id == request.id }) {
            assignmentRequests[index] = request
        } else {
            assignmentRequests.append(request)
        }
    }
    
    public func addConfirmedAssignment(_ assignment: ConfirmedAssignment) {
        confirmedAssignments.append(assignment)
    }
    
    public func updateConfirmedAssignment(_ assignment: ConfirmedAssignment) {
        if let index = confirmedAssignments.firstIndex(where: { $0.id == assignment.id }) {
            confirmedAssignments[index] = assignment
        } else {
            confirmedAssignments.append(assignment)
        }
    }
    
    public func addAlert(_ alert: CrowdAlert) {
        // Avoid duplicate alerts for same alertType and zone within recent timeframe
        let isDuplicate = alerts.contains {
            $0.alertType == alert.alertType &&
            $0.zoneID == alert.zoneID &&
            abs($0.createdAt.timeIntervalSince(alert.createdAt)) < 5.0
        }
        if !isDuplicate {
            alerts.insert(alert, at: 0)
        }
    }
    
    public func markAlertAsRead(id: UUID) {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].isRead = true
        }
    }
}
