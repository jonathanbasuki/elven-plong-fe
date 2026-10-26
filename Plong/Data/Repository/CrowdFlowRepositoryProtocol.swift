import Foundation
import Observation

@MainActor
public protocol CrowdFlowRepositoryProtocol: AnyObject {
    var zones: [VenueZone] { get }
    var staffMembers: [SecurityStaff] { get }
    var broadcasts: [BroadcastSession] { get }
    var alerts: [CrowdAlert] { get }
    var assignmentRequests: [AssignmentRequest] { get }
    var confirmedAssignments: [ConfirmedAssignment] { get }
    
    // Querying
    func getZone(by id: String) -> VenueZone?
    func getStaff(by id: UUID) -> SecurityStaff?
    func getCurrentBroadcast(for zoneId: String) -> BroadcastSession?
    func getBroadcast(by id: UUID) -> BroadcastSession?
    
    // Broadcast Contract Operations
    func createBroadcast(zoneId: String, staffNeeded: Int) throws -> BroadcastSession
    func respondToBroadcast(broadcastId: UUID, staffId: UUID) throws
    func completeBroadcast(broadcastId: UUID, staffId: UUID) throws
    func finishBroadcast(broadcastId: UUID) throws -> BroadcastSession
    
    // Updates
    func updateZone(_ zone: VenueZone)
    func updateStaff(_ staff: SecurityStaff)
    func updateBroadcast(_ session: BroadcastSession)
    
    // Alerts
    func addAlert(_ alert: CrowdAlert)
    func markAlertAsRead(id: UUID)
    
    // Backwards compatibility
    func getAssignmentRequest(by id: UUID) -> AssignmentRequest?
    func getConfirmedAssignment(by requestID: UUID) -> ConfirmedAssignment?
    func addAssignmentRequest(_ request: AssignmentRequest)
    func updateAssignmentRequest(_ request: AssignmentRequest)
    func addConfirmedAssignment(_ assignment: ConfirmedAssignment)
    func updateConfirmedAssignment(_ assignment: ConfirmedAssignment)
    
    func resetToDefaults()
}
