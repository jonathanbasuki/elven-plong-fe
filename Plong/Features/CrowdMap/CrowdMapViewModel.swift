import Foundation
import Observation

@Observable
@MainActor
public final class CrowdMapViewModel {
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    public let venueTitle: String = "Grand Arena & Exhibition Complex"
    
    public init(repository: CrowdFlowRepositoryProtocol, router: NavigationRouter) {
        self.repository = repository
        self.router = router
    }
    
    public var zones: [VenueZone] {
        repository.zones
    }
    
    public var totalCrowd: Int {
        repository.zones.reduce(0) { $0 + $1.crowdCount }
    }
    
    public var highCrowdZoneCount: Int {
        repository.zones.filter { $0.crowdSeverity == .high || $0.crowdSeverity == .critical }.count
    }
    
    public var confirmedAssignmentsCount: Int {
        repository.confirmedAssignments.count
    }
    
    public var unreadAlertsCount: Int {
        repository.alerts.filter { !$0.isRead }.count
    }
    
    public func assignedStaff(for zone: VenueZone) -> [SecurityStaff] {
        zone.assignedStaffIDs.compactMap { repository.getStaff(by: $0) }
    }
    
    public func selectZone(zoneID: UUID) {
        router.navigate(to: .zoneDetail(zoneID: zoneID))
    }
    
    public func openAlerts() {
        router.navigate(to: .alerts)
    }
}
