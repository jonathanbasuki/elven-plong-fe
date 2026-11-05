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
    public var instruction: String
    public var locationName: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        dateString: String,
        timeString: String,
        status: TaskLogStatus,
        zoneID: String? = nil,
        instruction: String = "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan",
        locationName: String = "Pantry"
    ) {
        self.id = id
        self.title = title
        self.dateString = dateString
        self.timeString = timeString
        self.status = status
        self.zoneID = zoneID
        self.instruction = instruction
        self.locationName = locationName
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
