import Foundation

public enum TaskLogStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case ongoing = "ongoing"
    case done = "done"
    
    public var title: String {
        switch self {
        case .ongoing: return "Ongoing"
        case .done: return "Done"
        }
    }
}

public struct TaskLogItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var dateString: String
    public var timeString: String
    public var status: TaskLogStatus
    public var zoneID: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        dateString: String,
        timeString: String,
        status: TaskLogStatus,
        zoneID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dateString = dateString
        self.timeString = timeString
        self.status = status
        self.zoneID = zoneID
    }
    
    public var formattedDateTime: String {
        if !timeString.isEmpty && !dateString.isEmpty {
            return "\(timeString), \(dateString)"
        } else if !dateString.isEmpty {
            return dateString
        } else {
            return timeString
        }
    }
}
