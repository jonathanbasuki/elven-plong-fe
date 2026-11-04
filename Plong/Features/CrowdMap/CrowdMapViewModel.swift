import Foundation
import Observation

@Observable
@MainActor
public final class CrowdMapViewModel {
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    public let venueTitle: String = "Grand Arena & Exhibition Complex"
    
    public var selectedZoneForDetail: VenueZone?
    public var isDetailModalPresented: Bool = false
    public var showProfileSheet: Bool = false
    
    public let coordinator: AssignmentCoordinator
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        coordinator: AssignmentCoordinator? = nil,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.coordinator = coordinator ?? AssignmentCoordinator(repository: repository)
        self.router = router
    }
    
    public var zones: [VenueZone] {
        repository.zones
    }
    
    public var activeStaffCount: Int {
        let count = repository.staffMembers.count
        return count > 0 ? count : 18
    }
    
    public var totalCrowd: Int {
        let sum = repository.zones.reduce(0) { $0 + $1.currentCount }
        return sum > 0 ? sum : 80
    }
    
    public var pantryZone: VenueZone? {
        zones.first { $0.name.localizedCaseInsensitiveContains("Pantry") || $0.id == MockDataConstants.zone1Id } ?? zones.first
    }
    
    public var collabZone: VenueZone? {
        zones.first { $0.name.localizedCaseInsensitiveContains("Collab") || $0.id == MockDataConstants.zone2Id }
    }
    
    public var meetingZone: VenueZone? {
        zones.first { $0.name.localizedCaseInsensitiveContains("Meeting") || $0.id == MockDataConstants.zone3Id }
    }
    
    public var availableStaffCount: Int {
        let idle = repository.staffMembers.filter { $0.status == .idle }.count
        return idle > 0 ? idle : 2
    }
    
    public func selectZoneForDetail(zone: VenueZone) {
        self.selectedZoneForDetail = zone
        self.isDetailModalPresented = true
    }
    
    public func confirmDelegation(zone: VenueZone, staffNeeded: Int, instruction: String) {
        do {
            try coordinator.startBroadcast(zoneID: zone.id, staffNeeded: staffNeeded)
            // Add accepted staff members to reflect the confirmed delegation
            for i in 0..<min(staffNeeded, repository.staffMembers.count) {
                let staff = repository.staffMembers[i]
                try? coordinator.staffRespond(staffId: staff.id)
            }
        } catch {
            // Handled or already active
        }
    }
    
    public func logout() {
        showProfileSheet = false
        router.isAuthenticated = false
        router.popToRoot()
    }
    
    public func openTaskLog() {
        router.navigate(to: .taskLog)
    }
}
