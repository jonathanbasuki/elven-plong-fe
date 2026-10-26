import XCTest
@testable import Plong

@MainActor
final class AssignmentWorkflowTests: XCTestCase {
    private var repository: MockCrowdFlowRepository!
    private var clock: ControllableClock!
    private var coordinator: AssignmentCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        clock = ControllableClock(initialDate: Date())
        repository = MockCrowdFlowRepository(clock: clock)
        coordinator = AssignmentCoordinator(repository: repository, clock: clock)
    }
    
    override func tearDown() async throws {
        coordinator = nil
        clock = nil
        repository = nil
        try await super.tearDown()
    }
    
    // 1. POST /broadcasts creates a session with 20s deadline and open status
    func test_createBroadcast_createsOpenSessionWith20sDeadline() throws {
        let zoneID = MockDataConstants.zone1Id
        let session = try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        XCTAssertEqual(session.zoneId, zoneID)
        XCTAssertEqual(session.staffNeeded, 3)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.acceptedCount, 0)
        XCTAssertEqual(session.completedCount, 0)
        XCTAssertEqual(session.expiresAt.timeIntervalSince(session.createdAt), 20.0, accuracy: 0.1)
    }
    
    // 2. POST /broadcasts fails with 409 broadcast_open if an open broadcast already exists for that zone
    func test_createBroadcast_failsIfBroadcastAlreadyOpen() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        // Attempting to create another open broadcast for the same zone
        XCTAssertThrowsError(try repository.createBroadcast(zoneId: zoneID, staffNeeded: 2)) { error in
            guard let bError = error as? BroadcastError, case .broadcastOpen = bError else {
                XCTFail("Expected .broadcastOpen error, got \(error)")
                return
            }
            XCTAssertEqual(bError.code, "broadcast_open")
        }
    }
    
    // 3. POST /broadcasts/{id}/respond adds staff to acceptedStaff and flips staff status to 'delegating'
    func test_staffRespond_addsToAcceptedStaffAndSetsStatusDelegating() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        // Aldi responds
        let aldiId = MockDataConstants.staffAldiId
        try coordinator.staffRespond(staffId: aldiId)
        
        let broadcast = coordinator.activeBroadcast
        XCTAssertEqual(broadcast?.acceptedCount, 1)
        XCTAssertEqual(broadcast?.acceptedStaff.first?.staffId, aldiId)
        XCTAssertEqual(broadcast?.acceptedStaff.first?.name, "Aldi")
        XCTAssertNil(broadcast?.acceptedStaff.first?.completedAt)
        
        // Staff status flips to delegating
        let aldi = repository.getStaff(by: aldiId)
        XCTAssertEqual(aldi?.status, .delegating)
    }
    
    // 4. POST /broadcasts/{id}/respond enforces hard cap at staff_needed (409 slots_full)
    func test_staffRespond_hardCapSlotsFull() throws {
        let zoneID = MockDataConstants.zone1Id
        // Cap set to 2 staff
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 2)
        
        // Slot 1: Aldi accepts
        try coordinator.staffRespond(staffId: MockDataConstants.staffAldiId)
        XCTAssertEqual(coordinator.activeBroadcast?.acceptedCount, 1)
        
        // Slot 2: Bunga accepts
        try coordinator.staffRespond(staffId: MockDataConstants.staffBungaId)
        XCTAssertEqual(coordinator.activeBroadcast?.acceptedCount, 2)
        XCTAssertTrue(coordinator.activeBroadcast?.isFull == true)
        
        // Slot 3: Citra tries to accept after cap is reached
        XCTAssertThrowsError(try coordinator.staffRespond(staffId: MockDataConstants.staffCitraId)) { error in
            guard let bError = error as? BroadcastError, case .slotsFull = bError else {
                XCTFail("Expected .slotsFull error, got \(error)")
                return
            }
            XCTAssertEqual(bError.code, "slots_full")
        }
    }
    
    // 5. POST /broadcasts/{id}/respond rejects responses after 20s deadline (409 expired)
    func test_staffRespond_expiredDeadlineRejected() throws {
        let zoneID = MockDataConstants.zone1Id
        let session = try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        // Advance clock past 20s
        clock.advance(by: 21.0)
        
        XCTAssertThrowsError(try repository.respondToBroadcast(broadcastId: session.id, staffId: MockDataConstants.staffAldiId)) { error in
            guard let bError = error as? BroadcastError, case .expired = bError else {
                XCTFail("Expected .expired error, got \(error)")
                return
            }
            XCTAssertEqual(bError.code, "expired")
        }
    }
    
    // 6. POST /broadcasts/{id}/complete sets completedAt and returns staff to 'idle'
    func test_staffComplete_setsCompletedAtAndFlipsStatusToIdle() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        let aldiId = MockDataConstants.staffAldiId
        try coordinator.staffRespond(staffId: aldiId)
        XCTAssertEqual(repository.getStaff(by: aldiId)?.status, .delegating)
        
        // Staff completes delegation
        try coordinator.staffComplete(staffId: aldiId)
        
        let broadcast = coordinator.activeBroadcast
        XCTAssertEqual(broadcast?.completedCount, 1)
        XCTAssertNotNil(broadcast?.acceptedStaff.first?.completedAt)
        XCTAssertTrue(broadcast?.acceptedStaff.first?.isCompleted == true)
        
        // Staff status returns to idle
        XCTAssertEqual(repository.getStaff(by: aldiId)?.status, .idle)
    }
    
    // 7. POST /broadcasts/{id}/complete fails with 403 not_your_response if staff never accepted
    func test_staffComplete_failsIfNotAccepted() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        // Citra never accepted
        let citraId = MockDataConstants.staffCitraId
        XCTAssertThrowsError(try coordinator.staffComplete(staffId: citraId)) { error in
            guard let bError = error as? BroadcastError, case .notYourResponse = bError else {
                XCTFail("Expected .notYourResponse error, got \(error)")
                return
            }
            XCTAssertEqual(bError.code, "not_your_response")
        }
    }
    
    // 8. POST /broadcasts/{id}/finish fails with 409 not_all_done if any accepted staff has not completed
    func test_finishBroadcast_failsIfNotAllDone() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 2)
        
        try coordinator.staffRespond(staffId: MockDataConstants.staffAldiId)
        try coordinator.staffRespond(staffId: MockDataConstants.staffBungaId)
        
        // Only Aldi completes
        try coordinator.staffComplete(staffId: MockDataConstants.staffAldiId)
        
        XCTAssertThrowsError(try coordinator.finishBroadcast()) { error in
            guard let bError = error as? BroadcastError, case .notAllDone = bError else {
                XCTFail("Expected .notAllDone error, got \(error)")
                return
            }
            XCTAssertEqual(bError.code, "not_all_done")
        }
    }
    
    // 9. POST /broadcasts/{id}/finish succeeds when all accepted staff have completed
    func test_finishBroadcast_succeedsWhenAllDone() throws {
        let zoneID = MockDataConstants.zone1Id
        try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 2)
        
        try coordinator.staffRespond(staffId: MockDataConstants.staffAldiId)
        try coordinator.staffRespond(staffId: MockDataConstants.staffBungaId)
        
        // Both complete
        try coordinator.staffComplete(staffId: MockDataConstants.staffAldiId)
        try coordinator.staffComplete(staffId: MockDataConstants.staffBungaId)
        
        XCTAssertTrue(coordinator.activeBroadcast?.isAllCompleted == true)
        
        let finished = try coordinator.finishBroadcast()
        XCTAssertEqual(finished.status, .finished)
        XCTAssertNotNil(finished.finishedAt)
    }
    
    // 10. "Try again" produces a brand-new broadcast row (not reopening the same ID)
    func test_tryAgain_createsNewBroadcastRow() throws {
        let zoneID = MockDataConstants.zone1Id
        let firstBroadcast = try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: 3)
        
        // Advance clock past expiration
        clock.advance(by: 21.0)
        
        // Countdown timer sets status = closed
        var closedBroadcast = firstBroadcast
        closedBroadcast.status = .closed
        repository.updateBroadcast(closedBroadcast)
        coordinator.activeBroadcast = closedBroadcast
        
        // Manager taps "Try again"
        let retryBroadcast = try coordinator.retryBroadcast()
        
        XCTAssertNotEqual(retryBroadcast.id, firstBroadcast.id, "Try again must produce a brand-new broadcast row")
        XCTAssertEqual(retryBroadcast.status, .open)
        XCTAssertEqual(retryBroadcast.zoneId, zoneID)
        XCTAssertEqual(retryBroadcast.staffNeeded, 3)
        XCTAssertEqual(retryBroadcast.acceptedCount, 0)
    }
}
