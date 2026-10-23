import Foundation
import Observation

@Observable
@MainActor
public final class ZoneDetailViewModel {
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
    
    public var assignedStaff: [SecurityStaff] {
        guard let zone = zone else { return [] }
        return zone.assignedStaffIDs.compactMap { repository.getStaff(by: $0) }
    }
    
    public func initiateBroadcast() {
        coordinator.startBroadcast(zoneID: zoneID, taskType: .security)
        router.navigate(to: .broadcast(zoneID: zoneID))
    }
    
    public func navigateBack() {
        router.pop()
    }
}
