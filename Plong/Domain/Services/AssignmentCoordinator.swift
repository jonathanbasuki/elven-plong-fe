import Foundation
import Observation

public enum BroadcastSessionStatus: Equatable, Sendable {
    case idle
    case selectingCandidate
    case waitingForResponse(staffID: UUID, remainingSeconds: Int)
    case accepted(assignmentID: UUID, staffName: String)
    case failedNoCandidates(reason: String)
    case cancelled
}

@Observable
@MainActor
public final class AssignmentCoordinator {
    public let repository: CrowdFlowRepositoryProtocol
    public let clock: ClockProtocol
    
    // Current active broadcast state
    public var currentZoneID: UUID?
    public var currentTaskType: AssignmentTaskType = .security
    public var currentRequest: AssignmentRequest?
    public var sessionStatus: BroadcastSessionStatus = .idle
    public var remainingSeconds: Int = 10
    public var attemptedStaffIDs: Set<UUID> = []
    
    // DEBUG control: force no candidates mode
    public var debugForceNoCandidates: Bool = false
    
    private var countdownTask: Task<Void, Never>?
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        clock: ClockProtocol = SystemClock()
    ) {
        self.repository = repository
        self.clock = clock
    }
    
    // MARK: - Eligibility & Selection
    
    public func getEligibleCandidates(
        for destinationZoneID: UUID,
        excluding excludedStaffIDs: Set<UUID> = []
    ) -> [SecurityStaff] {
        if debugForceNoCandidates {
            return []
        }
        
        let pendingStaffIDs = Set(
            repository.assignmentRequests
                .filter { $0.status == .pending }
                .map { $0.staffID }
        )
        
        let eligible = repository.staffMembers.filter { staff in
            // 1. Must be available
            guard staff.availabilityStatus == .available else { return false }
            // 2. Must not have active assignment
            guard staff.activeAssignmentID == nil else { return false }
            // 3. Must not have conflicting pending request
            guard !pendingStaffIDs.contains(staff.id) else { return false }
            // 4. Must not have been already attempted in this broadcast session
            guard !excludedStaffIDs.contains(staff.id) else { return false }
            return true
        }
        
        // Rank by mock distance ascending (nearest first)
        return eligible.sorted {
            $0.distance(to: destinationZoneID) < $1.distance(to: destinationZoneID)
        }
    }
    
    // MARK: - Broadcast Actions
    
    @discardableResult
    public func startBroadcast(
        zoneID: UUID,
        taskType: AssignmentTaskType = .security
    ) -> AssignmentRequest? {
        // Cancel any existing countdown
        cancelTimer()
        
        self.currentZoneID = zoneID
        self.currentTaskType = taskType
        self.attemptedStaffIDs = []
        self.sessionStatus = .selectingCandidate
        
        return dispatchNextCandidate(for: zoneID, taskType: taskType)
    }
    
    @discardableResult
    private func dispatchNextCandidate(
        for zoneID: UUID,
        taskType: AssignmentTaskType
    ) -> AssignmentRequest? {
        let candidates = getEligibleCandidates(for: zoneID, excluding: attemptedStaffIDs)
        
        guard let nearestCandidate = candidates.first else {
            // No eligible candidates remain
            sessionStatus = .failedNoCandidates(reason: "All available security personnel have declined, timed out, or are currently deployed.")
            currentRequest = nil
            
            repository.addAlert(CrowdAlert(
                zoneID: zoneID,
                alertType: .noAvailableSecurity,
                title: "No Available Security",
                message: "Deployment request failed. No eligible security personnel available in the venue.",
                createdAt: clock.now
            ))
            return nil
        }
        
        // 10-second acceptance window
        let expiresAt = clock.now.addingTimeInterval(10.0)
        let request = AssignmentRequest(
            id: UUID(),
            destinationZoneID: zoneID,
            staffID: nearestCandidate.id,
            taskType: taskType,
            status: .pending,
            createdAt: clock.now,
            expiresAt: expiresAt
        )
        
        // Mark candidate as busy while request is pending to prevent conflicting simultaneous broadcast assignment
        var updatedCandidate = nearestCandidate
        updatedCandidate.availabilityStatus = .busy
        repository.updateStaff(updatedCandidate)
        
        repository.addAssignmentRequest(request)
        self.currentRequest = request
        self.remainingSeconds = 10
        self.sessionStatus = .waitingForResponse(staffID: nearestCandidate.id, remainingSeconds: 10)
        
        // Emit Alert for Broadcast Sent
        let zoneName = repository.getZone(by: zoneID)?.name ?? "Zone"
        repository.addAlert(CrowdAlert(
            zoneID: zoneID,
            alertType: .securityBroadcastSent,
            title: "Security Broadcast Initiated",
            message: "Request dispatched to nearest personnel for \(zoneName).",
            createdAt: clock.now,
            relatedRequestID: request.id
        ))
        
        // Start countdown
        startCountdown(for: request.id, expiresAt: expiresAt)
        
        return request
    }
    
    // MARK: - Countdown Loop
    
    private func startCountdown(for requestID: UUID, expiresAt: Date) {
        cancelTimer()
        
        countdownTask = Task { [weak self] in
            while true {
                guard let self = self else { return }
                guard !Task.isCancelled else { return }
                guard self.currentRequest?.id == requestID else { return }
                
                let remaining = max(0, Int(ceil(expiresAt.timeIntervalSince(self.clock.now))))
                self.remainingSeconds = remaining
                
                if case .waitingForResponse(let staffID, _) = self.sessionStatus {
                    self.sessionStatus = .waitingForResponse(staffID: staffID, remainingSeconds: remaining)
                }
                
                if remaining <= 0 {
                    // Deadline reached
                    self.handleTimeout(for: requestID)
                    return
                }
                
                do {
                    try await self.clock.sleep(seconds: 1.0)
                } catch {
                    // Task cancelled
                    return
                }
            }
        }
    }
    
    private func cancelTimer() {
        countdownTask?.cancel()
        countdownTask = nil
    }
    
    // MARK: - State Transitions
    
    public func acceptCurrentRequest() {
        guard let request = currentRequest else { return }
        acceptRequest(requestID: request.id)
    }
    
    public func acceptRequest(requestID: UUID) {
        guard let request = repository.getAssignmentRequest(by: requestID) else { return }
        
        // Ensure request is pending and deadline has not passed
        guard request.status == .pending else { return }
        guard clock.now <= request.expiresAt else {
            handleTimeout(for: requestID)
            return
        }
        guard repository.getConfirmedAssignment(by: requestID) == nil else { return }
        
        cancelTimer()
        
        // Update request status
        var updatedRequest = request
        updatedRequest.status = .accepted
        repository.updateAssignmentRequest(updatedRequest)
        currentRequest = updatedRequest
        
        // Create confirmed assignment
        let confirmedAssignment = ConfirmedAssignment(
            requestID: request.id,
            staffID: request.staffID,
            destinationZoneID: request.destinationZoneID,
            taskType: request.taskType,
            progress: .accepted,
            confirmedAt: clock.now,
            updatedAt: clock.now
        )
        repository.addConfirmedAssignment(confirmedAssignment)
        
        // Associate staff with destination zone
        if var zone = repository.getZone(by: request.destinationZoneID) {
            if !zone.assignedStaffIDs.contains(request.staffID) {
                zone.assignedStaffIDs.append(request.staffID)
            }
            if zone.requiredAdditionalSecurity > 0 {
                zone.requiredAdditionalSecurity -= 1
            }
            repository.updateZone(zone)
        }
        
        // Mark staff member active assignment and busy
        let staffName: String
        if var staff = repository.getStaff(by: request.staffID) {
            staff.availabilityStatus = .busy
            staff.activeAssignmentID = confirmedAssignment.id
            repository.updateStaff(staff)
            staffName = staff.name
        } else {
            staffName = "Security Officer"
        }
        
        // Alert
        let zoneName = repository.getZone(by: request.destinationZoneID)?.name ?? "Zone"
        repository.addAlert(CrowdAlert(
            zoneID: request.destinationZoneID,
            alertType: .assignmentAccepted,
            title: "Security Assignment Confirmed",
            message: "\(staffName) accepted deployment to \(zoneName).",
            createdAt: clock.now,
            relatedRequestID: request.id
        ))
        
        sessionStatus = .accepted(assignmentID: confirmedAssignment.id, staffName: staffName)
    }
    
    public func declineCurrentRequest() {
        guard let request = currentRequest else { return }
        declineRequest(requestID: request.id)
    }
    
    public func declineRequest(requestID: UUID) {
        guard let request = repository.getAssignmentRequest(by: requestID) else { return }
        guard request.status == .pending else { return }
        
        cancelTimer()
        
        var updatedRequest = request
        updatedRequest.status = .declined
        repository.updateAssignmentRequest(updatedRequest)
        currentRequest = updatedRequest
        
        // Release candidate's busy lock so they return to available
        if var staff = repository.getStaff(by: request.staffID), staff.activeAssignmentID == nil {
            staff.availabilityStatus = .available
            repository.updateStaff(staff)
        }
        
        attemptedStaffIDs.insert(request.staffID)
        
        // Advance to next eligible candidate
        let targetZone = currentZoneID ?? request.destinationZoneID
        dispatchNextCandidate(for: targetZone, taskType: currentTaskType)
    }
    
    public func handleTimeout(for requestID: UUID) {
        guard let request = repository.getAssignmentRequest(by: requestID) else { return }
        guard request.status == .pending else { return }
        
        cancelTimer()
        
        var updatedRequest = request
        updatedRequest.status = .expired
        repository.updateAssignmentRequest(updatedRequest)
        currentRequest = updatedRequest
        
        // Release candidate's busy lock
        if var staff = repository.getStaff(by: request.staffID), staff.activeAssignmentID == nil {
            staff.availabilityStatus = .available
            repository.updateStaff(staff)
        }
        
        attemptedStaffIDs.insert(request.staffID)
        
        // Add expired alert
        let targetZone = currentZoneID ?? request.destinationZoneID
        let zoneName = repository.getZone(by: targetZone)?.name ?? "Zone"
        repository.addAlert(CrowdAlert(
            zoneID: targetZone,
            alertType: .assignmentRequestExpired,
            title: "Assignment Request Expired",
            message: "10-second acceptance window elapsed for \(zoneName). Searching next available candidate.",
            createdAt: clock.now,
            relatedRequestID: request.id
        ))
        
        // Advance to next eligible candidate
        dispatchNextCandidate(for: targetZone, taskType: currentTaskType)
    }
    
    public func cancelBroadcast() {
        cancelTimer()
        
        if let request = currentRequest, request.status == .pending {
            var updatedRequest = request
            updatedRequest.status = .cancelled
            repository.updateAssignmentRequest(updatedRequest)
            
            // Release staff lock
            if var staff = repository.getStaff(by: request.staffID), staff.activeAssignmentID == nil {
                staff.availabilityStatus = .available
                repository.updateStaff(staff)
            }
        }
        
        sessionStatus = .cancelled
    }
    
    public func resetSession() {
        cancelTimer()
        currentZoneID = nil
        currentRequest = nil
        sessionStatus = .idle
        attemptedStaffIDs = []
        remainingSeconds = 10
    }
}
