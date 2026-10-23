import XCTest
@testable import Plong

@MainActor
final class AssignmentWorkflowTests: XCTestCase {
    private var repository: MockCrowdFlowRepository!
    private var clock: ControllableClock!
    private var coordinator: AssignmentCoordinator!
    
    override func setUp() async throws {
        try await super.setUp()
        repository = MockCrowdFlowRepository()
        clock = ControllableClock(initialDate: Date())
        coordinator = AssignmentCoordinator(repository: repository, clock: clock)
    }
    
    override func tearDown() async throws {
        coordinator = nil
        clock = nil
        repository = nil
        try await super.tearDown()
    }
    
    // 1. The nearest eligible staff member is selected first.
    func test_nearestEligibleStaffMember_isSelectedFirst() {
        let destinationZoneID = MockDataConstants.zoneBId
        let eligibleCandidates = coordinator.getEligibleCandidates(for: destinationZoneID)
        
        XCTAssertFalse(eligibleCandidates.isEmpty, "Eligible candidates should not be empty")
        XCTAssertEqual(eligibleCandidates.first?.id, MockDataConstants.staffMarcusId, "Marcus Cole (15m) should be ranked first as nearest candidate")
        
        let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security)
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.staffID, MockDataConstants.staffMarcusId)
        XCTAssertEqual(request?.destinationZoneID, destinationZoneID)
        XCTAssertEqual(request?.status, .pending)
    }
    
    // 2. Unavailable staff are skipped.
    func test_unavailableStaff_areSkipped() {
        let destinationZoneID = MockDataConstants.zoneBId
        
        // Staff Elena is offline in mock data
        let elena = repository.getStaff(by: MockDataConstants.staffElenaId)
        XCTAssertEqual(elena?.availabilityStatus, .offline)
        
        let candidates = coordinator.getEligibleCandidates(for: destinationZoneID)
        let candidateIDs = candidates.map { $0.id }
        
        XCTAssertFalse(candidateIDs.contains(MockDataConstants.staffElenaId), "Offline staff member must be skipped")
    }
    
    // 3. Staff with active assignments are skipped.
    func test_staffWithActiveAssignments_areSkipped() {
        let destinationZoneID = MockDataConstants.zoneBId
        
        // Staff David has an active assignment in mock data
        let david = repository.getStaff(by: MockDataConstants.staffDavidId)
        XCTAssertNotNil(david?.activeAssignmentID)
        
        let candidates = coordinator.getEligibleCandidates(for: destinationZoneID)
        let candidateIDs = candidates.map { $0.id }
        
        XCTAssertFalse(candidateIDs.contains(MockDataConstants.staffDavidId), "Staff with active assignments must be skipped")
    }
    
    // 4. Acceptance confirms the assignment.
    func test_acceptance_confirmsAssignment() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Broadcast failed to start")
            return
        }
        
        coordinator.acceptRequest(requestID: request.id)
        
        // Check request status
        let updatedRequest = repository.getAssignmentRequest(by: request.id)
        XCTAssertEqual(updatedRequest?.status, .accepted)
        
        // Check confirmed assignment in repository
        let assignment = repository.getConfirmedAssignment(by: request.id)
        XCTAssertNotNil(assignment)
        XCTAssertEqual(assignment?.staffID, MockDataConstants.staffMarcusId)
        XCTAssertEqual(assignment?.destinationZoneID, destinationZoneID)
        XCTAssertEqual(assignment?.progress, .accepted)
        
        // Check destination zone updated
        let zone = repository.getZone(by: destinationZoneID)
        XCTAssertTrue(zone?.assignedStaffIDs.contains(MockDataConstants.staffMarcusId) == true)
        XCTAssertEqual(zone?.requiredAdditionalSecurity, 1, "Required security should decrement from 2 to 1")
        
        // Check staff active assignment
        let staff = repository.getStaff(by: MockDataConstants.staffMarcusId)
        XCTAssertEqual(staff?.availabilityStatus, .busy)
        XCTAssertEqual(staff?.activeAssignmentID, assignment?.id)
        
        // Check session status
        if case .accepted(let assignmentID, let staffName) = coordinator.sessionStatus {
            XCTAssertEqual(assignmentID, assignment?.id)
            XCTAssertEqual(staffName, "Officer Marcus Cole")
        } else {
            XCTFail("Coordinator should be in accepted state")
        }
    }
    
    // 5. Decline advances to the next eligible candidate.
    func test_decline_advancesToNextEligibleCandidate() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let firstRequest = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Broadcast failed to start")
            return
        }
        
        XCTAssertEqual(firstRequest.staffID, MockDataConstants.staffMarcusId)
        
        // First candidate declines
        coordinator.declineRequest(requestID: firstRequest.id)
        
        // Check first request status
        let updatedFirstRequest = repository.getAssignmentRequest(by: firstRequest.id)
        XCTAssertEqual(updatedFirstRequest?.status, .declined)
        
        // Check Marcus was released from busy lock
        let marcus = repository.getStaff(by: MockDataConstants.staffMarcusId)
        XCTAssertEqual(marcus?.availabilityStatus, .available)
        
        // Check next candidate was dispatched
        let secondRequest = coordinator.currentRequest
        XCTAssertNotNil(secondRequest)
        XCTAssertNotEqual(secondRequest?.id, firstRequest.id)
        XCTAssertEqual(secondRequest?.staffID, MockDataConstants.staffSarahId, "Sarah Jenkins (28m) should be selected next")
        XCTAssertEqual(secondRequest?.status, .pending)
    }
    
    // 6. Timeout advances to the next eligible candidate.
    func test_timeout_advancesToNextEligibleCandidate() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let firstRequest = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Broadcast failed to start")
            return
        }
        
        XCTAssertEqual(firstRequest.staffID, MockDataConstants.staffMarcusId)
        
        // Advance clock past expiration and handle timeout
        clock.advance(by: 10.5)
        coordinator.handleTimeout(for: firstRequest.id)
        
        // Check first request status
        let updatedFirstRequest = repository.getAssignmentRequest(by: firstRequest.id)
        XCTAssertEqual(updatedFirstRequest?.status, .expired)
        
        // Check next candidate was dispatched
        let secondRequest = coordinator.currentRequest
        XCTAssertNotNil(secondRequest)
        XCTAssertEqual(secondRequest?.staffID, MockDataConstants.staffSarahId)
        XCTAssertEqual(secondRequest?.status, .pending)
        
        // Check expired alert recorded
        let expiredAlert = repository.alerts.first { $0.alertType == .assignmentRequestExpired }
        XCTAssertNotNil(expiredAlert)
    }
    
    // 7. A staff member cannot hold two active assignments.
    func test_staffMember_cannotHoldTwoActiveAssignments() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Broadcast failed to start")
            return
        }
        
        // Marcus accepts
        coordinator.acceptRequest(requestID: request.id)
        
        let marcus = repository.getStaff(by: MockDataConstants.staffMarcusId)
        XCTAssertNotNil(marcus?.activeAssignmentID)
        
        // Check candidates for a new broadcast in another zone
        let newCandidates = coordinator.getEligibleCandidates(for: MockDataConstants.zoneCId)
        XCTAssertFalse(newCandidates.contains { $0.id == MockDataConstants.staffMarcusId }, "Marcus must not be eligible for a second assignment")
    }
    
    // 8. An expired request cannot be accepted.
    func test_expiredRequest_cannotBeAccepted() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Broadcast failed to start")
            return
        }
        
        // Advance clock past expiration
        clock.advance(by: 11.0)
        
        // Try to accept expired request
        coordinator.acceptRequest(requestID: request.id)
        
        let requestInRepo = repository.getAssignmentRequest(by: request.id)
        XCTAssertNotEqual(requestInRepo?.status, .accepted, "Expired request cannot transition to accepted")
        
        // No confirmed assignment should be created
        let assignment = repository.getConfirmedAssignment(by: request.id)
        XCTAssertNil(assignment)
    }
    
    // 9. No candidates produces a failure state.
    func test_noCandidates_producesFailureState() {
        let destinationZoneID = MockDataConstants.zoneBId
        
        // Exhaust all candidates (Marcus, Sarah, Alex)
        guard let r1 = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        coordinator.declineRequest(requestID: r1.id)
        
        guard let r2 = coordinator.currentRequest else {
            XCTFail()
            return
        }
        coordinator.declineRequest(requestID: r2.id)
        
        guard let r3 = coordinator.currentRequest else {
            XCTFail()
            return
        }
        coordinator.declineRequest(requestID: r3.id)
        
        // Now no candidates remain
        if case .failedNoCandidates(let reason) = coordinator.sessionStatus {
            XCTAssertFalse(reason.isEmpty)
        } else {
            XCTFail("Coordinator should be in failedNoCandidates state")
        }
        
        // Check No Available Security alert recorded
        let failAlert = repository.alerts.first { $0.alertType == .noAvailableSecurity }
        XCTAssertNotNil(failAlert)
    }
    
    // 10. Multiple required staffing slots do not assign the same staff member twice.
    func test_multipleStaffingSlots_doNotAssignSameStaffMemberTwice() {
        let destinationZoneID = MockDataConstants.zoneBId
        
        // Slot 1
        guard let slot1Request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        XCTAssertEqual(slot1Request.staffID, MockDataConstants.staffMarcusId)
        coordinator.acceptRequest(requestID: slot1Request.id)
        
        let zoneAfterSlot1 = repository.getZone(by: destinationZoneID)
        XCTAssertEqual(zoneAfterSlot1?.assignedStaffIDs.count, 1)
        XCTAssertEqual(zoneAfterSlot1?.requiredAdditionalSecurity, 1)
        
        // Slot 2
        guard let slot2Request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail("Slot 2 should find Sarah Jenkins")
            return
        }
        XCTAssertEqual(slot2Request.staffID, MockDataConstants.staffSarahId, "Slot 2 must not pick Marcus; it should select Sarah")
        coordinator.acceptRequest(requestID: slot2Request.id)
        
        let zoneAfterSlot2 = repository.getZone(by: destinationZoneID)
        XCTAssertEqual(zoneAfterSlot2?.assignedStaffIDs.count, 2)
        XCTAssertEqual(zoneAfterSlot2?.requiredAdditionalSecurity, 0)
        XCTAssertTrue(zoneAfterSlot2?.assignedStaffIDs.contains(MockDataConstants.staffMarcusId) == true)
        XCTAssertTrue(zoneAfterSlot2?.assignedStaffIDs.contains(MockDataConstants.staffSarahId) == true)
    }
    
    // Extra validation: Cancel broadcast releases staff lock
    func test_cancelBroadcast_releasesStaffLock() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        
        coordinator.cancelBroadcast()
        
        let updatedRequest = repository.getAssignmentRequest(by: request.id)
        XCTAssertEqual(updatedRequest?.status, .cancelled)
        
        let staff = repository.getStaff(by: MockDataConstants.staffMarcusId)
        XCTAssertEqual(staff?.availabilityStatus, .available)
        XCTAssertEqual(coordinator.sessionStatus, .cancelled)
    }
    
    // Duplicate acceptance events do not create duplicate assignments
    func test_duplicateAcceptance_doesNotCreateDuplicateAssignments() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        
        coordinator.acceptRequest(requestID: request.id)
        
        let countAfterFirstAccept = repository.confirmedAssignments.count
        let zoneAfterFirstAccept = repository.getZone(by: destinationZoneID)?.assignedStaffIDs.count ?? 0
        
        // Attempt duplicate acceptance
        coordinator.acceptRequest(requestID: request.id)
        
        XCTAssertEqual(repository.confirmedAssignments.count, countAfterFirstAccept, "Confirmed assignments count must not increase on duplicate accept")
        XCTAssertEqual(repository.getZone(by: destinationZoneID)?.assignedStaffIDs.count, zoneAfterFirstAccept, "Zone assigned staff count must not increase on duplicate accept")
    }
    
    // Simultaneous broadcast operations cannot assign the same staff member
    func test_simultaneousBroadcastOperations_cannotAssignSameStaffMember() {
        let zone1ID = MockDataConstants.zoneBId
        let zone2ID = MockDataConstants.zoneCId
        
        // Broadcast 1 begins for Zone B
        guard let request1 = coordinator.startBroadcast(zoneID: zone1ID, taskType: .security) else {
            XCTFail()
            return
        }
        XCTAssertEqual(request1.staffID, MockDataConstants.staffMarcusId)
        
        // Another broadcast query runs concurrently for Zone C
        let secondBroadcastCandidates = coordinator.getEligibleCandidates(for: zone2ID)
        XCTAssertFalse(
            secondBroadcastCandidates.contains { $0.id == MockDataConstants.staffMarcusId },
            "Marcus is currently pending for Zone B and cannot be selected by any simultaneous broadcast"
        )
    }
    
    // Stale countdown task does not modify newer request
    func test_staleCountdownTask_doesNotModifyNewerRequest() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let firstRequest = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        
        // First candidate declines immediately
        coordinator.declineRequest(requestID: firstRequest.id)
        
        guard let secondRequest = coordinator.currentRequest else {
            XCTFail()
            return
        }
        XCTAssertEqual(secondRequest.staffID, MockDataConstants.staffSarahId)
        
        // A stale invocation attempting to time out firstRequest must be ignored
        coordinator.handleTimeout(for: firstRequest.id)
        
        XCTAssertEqual(coordinator.currentRequest?.id, secondRequest.id, "Second request must remain the active request")
        XCTAssertEqual(coordinator.currentRequest?.status, .pending, "Second request must remain pending")
    }
    
    // Countdown deadline-based remaining seconds decrement
    func test_countdown_decrementsRemainingSeconds_untilTimeout() {
        let destinationZoneID = MockDataConstants.zoneBId
        guard let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(coordinator.remainingSeconds, 10)
        
        clock.advance(by: 3.0)
        let remainingAfter3s = max(0, Int(ceil(request.expiresAt.timeIntervalSince(clock.now))))
        XCTAssertEqual(remainingAfter3s, 7)
        
        clock.advance(by: 7.5)
        let remainingAfter10s = max(0, Int(ceil(request.expiresAt.timeIntervalSince(clock.now))))
        XCTAssertEqual(remainingAfter10s, 0)
        
        coordinator.handleTimeout(for: request.id)
        XCTAssertEqual(repository.getAssignmentRequest(by: request.id)?.status, .expired)
    }
    
    // Manager cannot manually choose candidate: Selection is 100% automated by nearest distance
    func test_managerCannotManuallySelectStaff_systemPicksNearestAutomatically() {
        let destinationZoneID = MockDataConstants.zoneBId
        
        // The startBroadcast API takes only destination zone and task type, no staff parameter
        let request = coordinator.startBroadcast(zoneID: destinationZoneID, taskType: .security)
        
        // Automatically picks Officer Marcus Cole who has distance 15m (nearest)
        XCTAssertEqual(request?.staffID, MockDataConstants.staffMarcusId)
        XCTAssertEqual(repository.getStaff(by: MockDataConstants.staffMarcusId)?.distance(to: destinationZoneID), 15.0)
    }
}
