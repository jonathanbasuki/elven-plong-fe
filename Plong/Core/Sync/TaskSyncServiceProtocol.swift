import Foundation

/// Protocol abstracting two-device synchronization.
/// Decouples the UI from the transport mechanism (MultipeerConnectivity today, WebSocket / REST backend tomorrow).
@MainActor
public protocol TaskSyncServiceProtocol: AnyObject {
    /// Current live connection state
    var connectionState: SyncConnectionState { get }
    
    /// Convenience boolean indicating if at least one peer is connected
    var isConnected: Bool { get }
    
    /// The local device's active role (Manager or Staff)
    var currentRole: UserRole { get }
    
    /// Start advertising & browsing for peers as the given role
    func start(as role: UserRole)
    
    /// Stop all networking sessions and release resources
    func stop()
    
    /// Broadcast a dispatched task from Manager to Staff
    func broadcastTaskDispatched(_ task: TaskLogItem)
    
    /// Broadcast a completed task acknowledgment from Staff to Manager
    func broadcastTaskCompleted(taskId: UUID, zoneId: String, zoneCount: Int, totalCrowd: Int)
    
    /// Callback triggered when a new task is received (on Staff device)
    var onTaskDispatched: ((TaskLogItem) -> Void)? { get set }
    
    /// Callback triggered when a task is completed (on Manager device)
    var onTaskCompleted: ((UUID, String, Int, Int) -> Void)? { get set }
    
    /// Callback triggered when the connection state changes
    var onConnectionChanged: ((SyncConnectionState) -> Void)? { get set }
}

