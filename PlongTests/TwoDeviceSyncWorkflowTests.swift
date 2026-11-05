import XCTest
@testable import Plong

@MainActor
final class MockTwoDeviceSyncChannel: TaskSyncServiceProtocol {
    public var connectionState: SyncConnectionState = .connected(peerName: "TestPeer")
    public var isConnected: Bool = true
    public var currentRole: UserRole = .manager
    
    // Wire connection to peer service
    public weak var peerService: MockTwoDeviceSyncChannel?
    
    public var onTaskDispatched: ((TaskLogItem) -> Void)?
    public var onTaskCompleted: ((UUID, String, Int, Int) -> Void)?
    public var onConnectionChanged: ((SyncConnectionState) -> Void)?
    
    public init(role: UserRole) {
        self.currentRole = role
    }
    
    public func start(as role: UserRole) {
        self.currentRole = role
        self.connectionState = .connected(peerName: "MockPeer")
        self.onConnectionChanged?(.connected(peerName: "MockPeer"))
    }
    
    public func stop() {
        self.connectionState = .disconnected
        self.onConnectionChanged?(.disconnected)
    }
    
    public func broadcastTaskDispatched(_ task: TaskLogItem) {
        peerService?.onTaskDispatched?(task)
    }
    
    public func broadcastTaskCompleted(taskId: UUID, zoneId: String, zoneCount: Int, totalCrowd: Int) {
        peerService?.onTaskCompleted?(taskId, zoneId, zoneCount, totalCrowd)
    }
}

@MainActor
final class TwoDeviceSyncWorkflowTests: XCTestCase {
    private var managerSync: MockTwoDeviceSyncChannel!
    private var staffSync: MockTwoDeviceSyncChannel!
    private var managerRepo: MockCrowdFlowRepository!
    private var staffRepo: MockCrowdFlowRepository!
    private var managerRouter: NavigationRouter!
    private var staffRouter: NavigationRouter!
    
    override func setUp() async throws {
        try await super.setUp()
        managerSync = MockTwoDeviceSyncChannel(role: .manager)
        staffSync = MockTwoDeviceSyncChannel(role: .staff)
        managerSync.peerService = staffSync
        staffSync.peerService = managerSync
        
        managerRepo = MockCrowdFlowRepository()
        staffRepo = MockCrowdFlowRepository()
        managerRouter = NavigationRouter(isAuthenticated: true, currentUserRole: .manager)
        staffRouter = NavigationRouter(isAuthenticated: true, currentUserRole: .staff)
    }
    
    override func tearDown() async throws {
        managerSync = nil
        staffSync = nil
        managerRepo = nil
        staffRepo = nil
        managerRouter = nil
        staffRouter = nil
        try await super.tearDown()
    }
    
    // 1. Serialization Test: SyncMessage encodes and decodes JSON losslessly
    func test_syncMessageSerialization_lossless() throws {
        let task = TaskLogItem(
            id: UUID(),
            title: "Overflow in Pantry",
            dateString: "5 Oct 2026",
            timeString: "14:05",
            status: .ongoing,
            zoneID: "zone-1",
            instruction: "Clear crowd at pantry entrance",
            locationName: "Pantry"
        )
        let message = SyncMessage(
            action: .taskDispatched,
            task: task,
            taskId: task.id,
            zoneId: "zone-1",
            zoneCount: 50,
            totalCrowd: 80,
            senderRole: .manager,
            senderDeviceName: "Manager's iPhone"
        )
        
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(SyncMessage.self, from: encoded)
        
        XCTAssertEqual(decoded.action, .taskDispatched)
        XCTAssertEqual(decoded.task?.id, task.id)
        XCTAssertEqual(decoded.task?.title, "Overflow in Pantry")
        XCTAssertEqual(decoded.senderRole, .manager)
        XCTAssertEqual(decoded.senderDeviceName, "Manager's iPhone")
    }
    
    // 2. End-to-End Two Device Flow:
    // Manager assigns task -> Staff receives alert -> Staff marks done -> Manager reflects done
    func test_twoDeviceWorkflow_dispatchAndCompletion() throws {
        // Setup Manager ViewModel
        let managerVM = CrowdMapViewModel(
            repository: managerRepo,
            syncService: managerSync,
            router: managerRouter
        )
        
        // Target zone
        guard let pantry = managerVM.pantryZone else {
            XCTFail("Pantry zone must exist")
            return
        }
        XCTAssertEqual(pantry.currentCount, 50)
        XCTAssertEqual(managerVM.totalCrowd, 80)
        XCTAssertEqual(managerVM.delegationStatus, .none)
        
        // Track task received on Staff device
        var receivedTaskOnStaff: TaskLogItem?
        staffSync.onTaskDispatched = { task in
            receivedTaskOnStaff = task
        }
        
        // Action 1: Manager delegates task
        managerVM.confirmDelegation(
            zone: pantry,
            staffNeeded: 3,
            instruction: "Tolong segera amankan area pantry"
        )
        
        // Verify Manager local state is ongoing
        XCTAssertEqual(managerVM.delegationStatus, .ongoing)
        
        // Verify Staff device received dispatched task
        XCTAssertNotNil(receivedTaskOnStaff)
        XCTAssertEqual(receivedTaskOnStaff?.locationName, pantry.name)
        XCTAssertEqual(receivedTaskOnStaff?.instruction, "Tolong segera amankan area pantry")
        XCTAssertEqual(receivedTaskOnStaff?.status, .ongoing)
        
        // Action 2: Staff marks task completed
        staffSync.broadcastTaskCompleted(
            taskId: receivedTaskOnStaff!.id,
            zoneId: pantry.id,
            zoneCount: 15,
            totalCrowd: 45
        )
        
        // Verify Manager device reflects completion automatically!
        XCTAssertEqual(managerVM.delegationStatus, .done)
        XCTAssertEqual(managerVM.pantryZone?.currentCount, 15)
        XCTAssertEqual(managerVM.totalCrowd, 45)
    }
}

