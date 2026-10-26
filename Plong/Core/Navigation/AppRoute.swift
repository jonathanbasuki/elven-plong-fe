import Foundation

public enum AppRoute: Hashable, Sendable {
    case crowdMap
    case zoneDetail(zoneID: String)
    case createBroadcast(zoneID: String)
    case broadcast(zoneID: String)
    @available(*, deprecated, message: "Deprecated in favor of Broadcast flow (.broadcast(zoneID:))")
    case assignmentStatus(requestID: UUID)
    case alerts
}
