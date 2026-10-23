import Foundation

public enum AssignmentProgressStatus: String, Codable, CaseIterable, Sendable {
    case accepted = "Accepted"
    case onTheWay = "On The Way"
    case onSite = "On Site"
    case completed = "Completed"
}

public struct ConfirmedAssignment: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let requestID: UUID
    public let staffID: UUID
    public let destinationZoneID: UUID
    public let taskType: AssignmentTaskType
    public var progress: AssignmentProgressStatus
    public let confirmedAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        requestID: UUID,
        staffID: UUID,
        destinationZoneID: UUID,
        taskType: AssignmentTaskType,
        progress: AssignmentProgressStatus = .accepted,
        confirmedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.requestID = requestID
        self.staffID = staffID
        self.destinationZoneID = destinationZoneID
        self.taskType = taskType
        self.progress = progress
        self.confirmedAt = confirmedAt
        self.updatedAt = updatedAt
    }
}
