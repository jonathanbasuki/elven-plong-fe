import Foundation

public enum AlertType: String, Codable, CaseIterable, Sendable {
    case highCrowdDetected = "High Crowd Detected"
    case crowdDensityIncreasing = "Crowd Density Increasing"
    case securityBroadcastSent = "Security Broadcast Sent"
    case assignmentAccepted = "Assignment Accepted"
    case assignmentRequestExpired = "Assignment Request Expired"
    case noAvailableSecurity = "No Available Security"
}

public struct CrowdAlert: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let zoneID: UUID
    public let alertType: AlertType
    public let title: String
    public let message: String
    public let createdAt: Date
    public var isRead: Bool
    public var relatedRequestID: UUID?
    
    public init(
        id: UUID = UUID(),
        zoneID: UUID,
        alertType: AlertType,
        title: String,
        message: String,
        createdAt: Date = Date(),
        isRead: Bool = false,
        relatedRequestID: UUID? = nil
    ) {
        self.id = id
        self.zoneID = zoneID
        self.alertType = alertType
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = isRead
        self.relatedRequestID = relatedRequestID
    }
}
