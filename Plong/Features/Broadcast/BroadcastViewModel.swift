import Foundation
import Observation

@Observable
@MainActor
public final class BroadcastViewModel {
    public let zoneID: String
    public let repository: CrowdFlowRepositoryProtocol
    public let coordinator: AssignmentCoordinator
    public let router: NavigationRouter
    
    public var errorMessage: String? = nil
    
    public init(
        zoneID: String,
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
    
    public var broadcast: BroadcastSession? {
        coordinator.activeBroadcast ?? repository.getCurrentBroadcast(for: zoneID)
    }
    
    public var remainingSeconds: Int {
        coordinator.remainingSeconds
    }
    
    public var staffMembers: [SecurityStaff] {
        repository.staffMembers
    }
    
    public var availableStaffForSimulation: [SecurityStaff] {
        guard let b = broadcast else { return [] }
        let acceptedIds = Set(b.acceptedStaff.map { $0.staffId })
        return staffMembers.filter { !acceptedIds.contains($0.id) }
    }
    
    public var isAllDone: Bool {
        broadcast?.isAllCompleted == true
    }
    
    // MARK: - Actions
    
    public func tryAgain() {
        errorMessage = nil
        do {
            try coordinator.retryBroadcast()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func simulateStaffAccept(staffId: UUID) {
        errorMessage = nil
        do {
            try coordinator.staffRespond(staffId: staffId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func simulateStaffComplete(staffId: UUID) {
        errorMessage = nil
        do {
            try coordinator.staffComplete(staffId: staffId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func finishBroadcast() {
        errorMessage = nil
        do {
            try coordinator.finishBroadcast()
            // Contract: finish ends the broadcast and sends manager back to page 1
            router.pop()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func cancelBroadcast() {
        coordinator.cancelBroadcast()
        router.pop()
    }
    
    public func backToZone() {
        router.pop()
    }
    
    public func backToMap() {
        router.popToRoot()
    }
}
