import Foundation

public enum AppRoute: Hashable, Sendable {
    case crowdMap
    case zoneDetail(zoneID: UUID)
    case broadcast(zoneID: UUID)
    case assignmentStatus(requestID: UUID)
    case alerts
}
