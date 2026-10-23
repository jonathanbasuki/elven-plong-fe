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
            // Assignment alerts navigate to assignment status if request ID is known, else zone detail
            if let requestID = alert.relatedRequestID {
                router.navigate(to: .assignmentStatus(requestID: requestID))
            } else {
                router.navigate(to: .zoneDetail(zoneID: alert.zoneID))
            }
        }
    }
    
    public func getZoneName(for zoneID: UUID) -> String {
        repository.getZone(by: zoneID)?.name ?? "Zone"
    }
    
    public func navigateBack() {
        router.pop()
    }
}
