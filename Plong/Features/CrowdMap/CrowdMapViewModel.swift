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
    public var delegationStatus: ZoneDelegationStatus = .none
    
    public let coordinator: AssignmentCoordinator
    public let syncService: TaskSyncServiceProtocol
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        coordinator: AssignmentCoordinator? = nil,
        syncService: TaskSyncServiceProtocol = MultipeerTaskSyncService.shared,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.coordinator = coordinator ?? AssignmentCoordinator(repository: repository)
        self.syncService = syncService
        self.router = router
        setupSyncSubscriptions()
    }
    
    public var zones: [VenueZone] {
        repository.zones
    }
    
    public var activeStaffCount: Int {
        18
    }
    
    public var totalCrowd: Int {
        if delegationStatus == .done {
            return 45
        }
        let sum = repository.zones.reduce(0) { $0 + $1.currentCount }
        return sum > 0 ? sum : 80
    }
    
    public var pantryZone: VenueZone? {
        let base = zones.first { $0.name.localizedCaseInsensitiveContains("Pantry") || $0.id == MockDataConstants.zone1Id } ?? zones.first
        guard let p = base else { return nil }
        if delegationStatus == .done {
            var updated = p
            updated.currentCount = 15
            return updated
        }
        return p
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
        delegationStatus = .ongoing
        do {
            try coordinator.startBroadcast(zoneID: zone.id, staffNeeded: staffNeeded)
            for i in 0..<min(staffNeeded, repository.staffMembers.count) {
                let staff = repository.staffMembers[i]
                try? coordinator.staffRespond(staffId: staff.id)
            }
        } catch {
            // Handled
        }
        
        // Broadcast task to Staff device over peer-to-peer sync
        let cleanInstruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let dispatchedTask = TaskLogItem(
            id: UUID(),
            title: "Overflow in \(zone.name)",
            dateString: "5 Oct 2026",
            timeString: "14:05",
            status: .ongoing,
            zoneID: zone.id,
            instruction: cleanInstruction.isEmpty
                ? "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan"
                : cleanInstruction,
            locationName: zone.name
        )
        syncService.broadcastTaskDispatched(dispatchedTask)
    }
    
    public func completeDelegation() {
        delegationStatus = .done
        try? coordinator.finishBroadcast()
        if var pantry = zones.first(where: { $0.name.localizedCaseInsensitiveContains("Pantry") || $0.id == MockDataConstants.zone1Id }) {
            pantry.currentCount = 15
            repository.updateZone(pantry)
        }
    }
    
    private func setupSyncSubscriptions() {
        syncService.onTaskCompleted = { [weak self] taskId, zoneId, zoneCount, totalCrowd in
            guard let self = self else { return }
            self.completeDelegation()
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
