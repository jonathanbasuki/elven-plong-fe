import Foundation
import Observation

@Observable
@MainActor
@available(*, deprecated, message: "Use BroadcastViewModel instead")
public final class AssignmentStatusViewModel {
    public let requestID: UUID
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    
    public init(
        requestID: UUID,
        repository: CrowdFlowRepositoryProtocol,
        router: NavigationRouter
    ) {
        self.requestID = requestID
        self.repository = repository
        self.router = router
    }
    
    public var request: AssignmentRequest? {
        repository.getAssignmentRequest(by: requestID)
    }
    
    public var confirmedAssignment: ConfirmedAssignment? {
        repository.getConfirmedAssignment(by: requestID)
    }
    
    public var destinationZone: VenueZone? {
        guard let request = request else { return nil }
        return repository.getZone(by: request.destinationZoneID)
    }
    
    public var assignedStaff: SecurityStaff? {
        guard let request = request else { return nil }
        return repository.getStaff(by: request.staffID)
    }
    
    public func advanceProgress() {
        guard var assignment = confirmedAssignment else { return }
        switch assignment.progress {
        case .accepted:
            assignment.progress = .onTheWay
        case .onTheWay:
            assignment.progress = .onSite
        case .onSite:
            assignment.progress = .completed
        case .completed:
            break
        }
        assignment.updatedAt = Date()
        repository.updateConfirmedAssignment(assignment)
    }
    
    public func navigateToZoneDetail() {
        if let zone = destinationZone {
            router.navigate(to: .zoneDetail(zoneID: zone.id))
        } else {
            router.pop()
        }
    }
    
    public func navigateToMap() {
        router.popToRoot()
    }
}
