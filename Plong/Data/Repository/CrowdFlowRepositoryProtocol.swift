import Foundation
import Observation

@MainActor
public protocol CrowdFlowRepositoryProtocol: AnyObject {
    var zones: [VenueZone] { get }
    var staffMembers: [SecurityStaff] { get }
    var alerts: [CrowdAlert] { get }
    var assignmentRequests: [AssignmentRequest] { get }
    var confirmedAssignments: [ConfirmedAssignment] { get }
    
    func getZone(by id: UUID) -> VenueZone?
    func getStaff(by id: UUID) -> SecurityStaff?
    func getAssignmentRequest(by id: UUID) -> AssignmentRequest?
    func getConfirmedAssignment(by requestID: UUID) -> ConfirmedAssignment?
    
    func updateZone(_ zone: VenueZone)
    func updateStaff(_ staff: SecurityStaff)
    func addAssignmentRequest(_ request: AssignmentRequest)
    func updateAssignmentRequest(_ request: AssignmentRequest)
    func addConfirmedAssignment(_ assignment: ConfirmedAssignment)
    func updateConfirmedAssignment(_ assignment: ConfirmedAssignment)
    
    func addAlert(_ alert: CrowdAlert)
    func markAlertAsRead(id: UUID)
    
    func resetToDefaults()
}
