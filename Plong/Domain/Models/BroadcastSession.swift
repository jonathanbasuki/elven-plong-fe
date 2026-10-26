import Foundation

public enum BroadcastStatus: String, Codable, CaseIterable, Sendable {
    case open = "open"
    case closed = "closed"
    case finished = "finished"
    
    public var label: String {
        switch self {
        case .open: return "Open"
        case .closed: return "Closed"
        case .finished: return "Finished"
        }
    }
}

public struct AcceptedStaffItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID { staffId }
    public let staffId: UUID
    public let name: String
    public var respondedAt: Date
    public var completedAt: Date?
    
    public var isCompleted: Bool {
        completedAt != nil
    }
    
    public init(
        staffId: UUID,
        name: String,
        respondedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.staffId = staffId
        self.name = name
        self.respondedAt = respondedAt
        self.completedAt = completedAt
    }
}

public struct BroadcastSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID // broadcast_id
    public let zoneId: String
    public var staffNeeded: Int
    public var status: BroadcastStatus
    public let createdAt: Date
    public var expiresAt: Date
    public var finishedAt: Date?
    public var acceptedStaff: [AcceptedStaffItem]
    
    public var acceptedCount: Int {
        acceptedStaff.count
    }
    
    public var completedCount: Int {
        acceptedStaff.filter { $0.isCompleted }.count
    }
    
    public var isFull: Bool {
        acceptedCount >= staffNeeded
    }
    
    public var isAllCompleted: Bool {
        acceptedCount >= 1 && completedCount == acceptedCount
    }
    
    public init(
        id: UUID = UUID(),
        zoneId: String,
        staffNeeded: Int,
        status: BroadcastStatus = .open,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        finishedAt: Date? = nil,
        acceptedStaff: [AcceptedStaffItem] = []
    ) {
        self.id = id
        self.zoneId = zoneId
        self.staffNeeded = staffNeeded
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(20.0)
        self.finishedAt = finishedAt
        self.acceptedStaff = acceptedStaff
    }
}

public enum BroadcastError: Error, LocalizedError, Equatable {
    case notFound(String)
    case broadcastOpen(String)
    case expired(String)
    case slotsFull(String)
    case notYourResponse(String)
    case notAllDone(String)
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let msg): return msg
        case .broadcastOpen(let msg): return msg
        case .expired(let msg): return msg
        case .slotsFull(let msg): return msg
        case .notYourResponse(let msg): return msg
        case .notAllDone(let msg): return msg
        }
    }
    
    public var code: String {
        switch self {
        case .notFound: return "not_found"
        case .broadcastOpen: return "broadcast_open"
        case .expired: return "expired"
        case .slotsFull: return "slots_full"
        case .notYourResponse: return "not_your_response"
        case .notAllDone: return "not_all_done"
        }
    }
}
