import Foundation
import Observation

@Observable
@MainActor
public final class BroadcastViewModel {
    public let zoneID: UUID
    public let repository: CrowdFlowRepositoryProtocol
    public let coordinator: AssignmentCoordinator
    public let router: NavigationRouter
    
    public init(
        zoneID: UUID,
        repository: CrowdFlowRepositoryProtocol,
        coordinator: AssignmentCoordinator,
        router: NavigationRouter
    ) {
        self.zoneID = zoneID
        self.repository = repository
        self.coordinator = coordinator
        self.router = router
    }
    
    public var zone: VenueZone? {
        repository.getZone(by: zoneID)
    }
    
    public var sessionStatus: BroadcastSessionStatus {
        coordinator.sessionStatus
    }
    
    public var remainingSeconds: Int {
        coordinator.remainingSeconds
    }
    
    public var taskType: AssignmentTaskType {
        coordinator.currentTaskType
    }
    
    public var currentRequest: AssignmentRequest? {
        coordinator.currentRequest
    }
    
    public var attemptedCandidatesCount: Int {
        coordinator.attemptedStaffIDs.count
    }
    
    public func cancelBroadcast() {
        coordinator.cancelBroadcast()
        router.pop()
    }
    
    public func viewAssignmentStatus(requestID: UUID) {
        router.navigate(to: .assignmentStatus(requestID: requestID))
    }
    
    public func backToZone() {
        router.pop()
    }
    
    public func backToMap() {
        router.popToRoot()
    }
    
    // MARK: - Debug Mock Controls
    
    public func debugSimulateAccept() {
        coordinator.acceptCurrentRequest()
    }
    
    public func debugSimulateDecline() {
        coordinator.declineCurrentRequest()
    }
    
    public func debugSimulateTimeout() {
        if let request = coordinator.currentRequest {
            coordinator.handleTimeout(for: request.id)
        }
    }
    
    public func debugToggleForceNoCandidates() {
        coordinator.debugForceNoCandidates.toggle()
        if coordinator.debugForceNoCandidates {
            // Re-trigger dispatch with empty candidate pool
            coordinator.startBroadcast(zoneID: zoneID, taskType: taskType)
        }
    }
}
