import Foundation

public enum AssignmentTaskType: String, Codable, CaseIterable, Sendable {
    case security = "Security Manpower"
    case crowdControl = "Crowd Control"
}

public enum RequestStatus: String, Codable, CaseIterable, Sendable {
    case pending = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"
    case cancelled = "Cancelled"
}

public struct AssignmentRequest: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let destinationZoneID: UUID
    public let staffID: UUID
    public let taskType: AssignmentTaskType
    public var status: RequestStatus
    public let createdAt: Date
    public let expiresAt: Date
    
    public init(
        id: UUID = UUID(),
        destinationZoneID: UUID,
        staffID: UUID,
        taskType: AssignmentTaskType = .security,
        status: RequestStatus = .pending,
        createdAt: Date = Date(),
        expiresAt: Date
    ) {
        self.id = id
        self.destinationZoneID = destinationZoneID
        self.staffID = staffID
        self.taskType = taskType
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
