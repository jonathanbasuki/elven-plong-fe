import Foundation
import Observation

@Observable
@MainActor
public final class AlertsViewModel {
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.router = router
    }
    
    public var alerts: [CrowdAlert] {
        repository.alerts
    }
    
    public func selectAlert(_ alert: CrowdAlert) {
        repository.markAlertAsRead(id: alert.id)
        
        switch alert.alertType {
        case .highCrowdDetected, .crowdDensityIncreasing, .noAvailableSecurity:
            // Crowd/Zone alerts navigate to relevant Zone Detail
            router.navigate(to: .zoneDetail(zoneID: alert.zoneID))
            
        case .securityBroadcastSent, .assignmentAccepted, .assignmentRequestExpired:
            // If broadcast is active, navigate to live broadcast or zone detail
            router.navigate(to: .zoneDetail(zoneID: alert.zoneID))
        }
    }
    
    public func getZoneName(for zoneID: String) -> String {
        repository.getZone(by: zoneID)?.name ?? "Zone \(zoneID)"
    }
    
    public func navigateBack() {
        router.pop()
    }
}
