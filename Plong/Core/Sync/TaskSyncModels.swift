import Foundation

/// Action types supported by the peer-to-peer and backend synchronization layer.
public enum SyncAction: String, Codable, Sendable {
    case taskDispatched = "task_dispatched"
    case taskCompleted = "task_completed"
    case syncState = "sync_state"
}

/// Unified network sync payload transferred between Manager and Staff devices.
/// Easily serialized to JSON for MultipeerConnectivity or future REST/WebSocket transport.
public struct SyncMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let action: SyncAction
    public let task: TaskLogItem?
    public let taskId: UUID?
    public let zoneId: String?
    public let zoneCount: Int?
    public let totalCrowd: Int?
    public let senderRole: UserRole
    public let senderDeviceName: String
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        action: SyncAction,
        task: TaskLogItem? = nil,
        taskId: UUID? = nil,
        zoneId: String? = nil,
        zoneCount: Int? = nil,
        totalCrowd: Int? = nil,
        senderRole: UserRole,
        senderDeviceName: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.action = action
        self.task = task
        self.taskId = taskId
        self.zoneId = zoneId
        self.zoneCount = zoneCount
        self.totalCrowd = totalCrowd
        self.senderRole = senderRole
        self.senderDeviceName = senderDeviceName
        self.timestamp = timestamp
    }
}

/// Connection lifecycle state between devices.
public enum SyncConnectionState: Equatable, Sendable {
    case disconnected
    case searching
    case connected(peerName: String)
    
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    public var peerName: String? {
        if case .connected(let name) = self {
            return name
        }
        return nil
    }
    
    public var displayTitle: String {
        switch self {
        case .disconnected:
            return "Offline"
        case .searching:
            return "Searching for peers..."
        case .connected(let name):
            return "Connected: \(name)"
        }
    }
}

