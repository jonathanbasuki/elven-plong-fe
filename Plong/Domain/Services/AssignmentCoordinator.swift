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
    
    // Active broadcast state
    public var currentZoneID: String?
    public var activeBroadcast: BroadcastSession?
    public var remainingSeconds: Int = 20
    public var lastError: String?
    
    // Legacy compatibility properties
    public var currentRequest: AssignmentRequest? {
        guard let b = activeBroadcast, let first = b.acceptedStaff.first else { return nil }
        return AssignmentRequest(
            id: b.id,
            destinationZoneID: b.zoneId,
            staffID: first.staffId,
            status: .accepted,
            createdAt: b.createdAt,
            expiresAt: b.expiresAt
        )
    }
    
    public var attemptedStaffIDs: Set<UUID> {
        guard let b = activeBroadcast else { return [] }
        return Set(b.acceptedStaff.map { $0.staffId })
    }
    
    public var sessionStatus: BroadcastSessionStatus {
        guard let b = activeBroadcast else { return .idle }
        switch b.status {
        case .open:
            if let first = b.acceptedStaff.first {
                return .waitingForResponse(staffID: first.staffId, remainingSeconds: remainingSeconds)
            } else {
                return .waitingForResponse(staffID: UUID(), remainingSeconds: remainingSeconds)
            }
        case .closed:
            if b.acceptedCount == 0 {
                return .failedNoCandidates(reason: "No staff accepted within 20 seconds deadline.")
            } else {
                return .accepted(assignmentID: b.id, staffName: b.acceptedStaff.map { $0.name }.joined(separator: ", "))
            }
        case .finished:
            return .accepted(assignmentID: b.id, staffName: "Completed")
        }
    }
    
    private var countdownTask: Task<Void, Never>?
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        clock: ClockProtocol = SystemClock()
    ) {
        self.repository = repository
        self.clock = clock
    }
    
    // MARK: - Broadcast Actions
    
    @discardableResult
    public func startBroadcast(
        zoneID: String,
        staffNeeded: Int = 3
    ) throws -> BroadcastSession {
        cancelTimer()
        self.currentZoneID = zoneID
        self.lastError = nil
        
        let session = try repository.createBroadcast(zoneId: zoneID, staffNeeded: staffNeeded)
        self.activeBroadcast = session
        self.remainingSeconds = 20
        
        startCountdown(for: session.id, expiresAt: session.expiresAt)
        return session
    }
    
    @discardableResult
    public func retryBroadcast() throws -> BroadcastSession {
        guard let current = activeBroadcast else {
            throw BroadcastError.notFound("No active broadcast to retry.")
        }
        return try startBroadcast(zoneID: current.zoneId, staffNeeded: current.staffNeeded)
    }
    
    public func staffRespond(staffId: UUID) throws {
        guard let session = activeBroadcast else {
            throw BroadcastError.notFound("No active broadcast.")
        }
        
        try repository.respondToBroadcast(broadcastId: session.id, staffId: staffId)
        
        // Refresh local broadcast state
        if let updated = repository.getBroadcast(by: session.id) {
            self.activeBroadcast = updated
        }
    }
    
    public func staffComplete(staffId: UUID) throws {
        guard let session = activeBroadcast else {
            throw BroadcastError.notFound("No active broadcast.")
        }
        
        try repository.completeBroadcast(broadcastId: session.id, staffId: staffId)
        
        if let updated = repository.getBroadcast(by: session.id) {
            self.activeBroadcast = updated
        }
    }
    
    @discardableResult
    public func finishBroadcast() throws -> BroadcastSession {
        guard let session = activeBroadcast else {
            throw BroadcastError.notFound("No active broadcast.")
        }
        
        let finished = try repository.finishBroadcast(broadcastId: session.id)
        self.activeBroadcast = finished
        cancelTimer()
        return finished
    }
    
    public func cancelBroadcast() {
        cancelTimer()
        if var session = activeBroadcast, session.status == .open {
            session.status = .closed
            repository.updateBroadcast(session)
            self.activeBroadcast = session
        }
    }
    
    public func resetSession() {
        cancelTimer()
        self.currentZoneID = nil
        self.activeBroadcast = nil
        self.remainingSeconds = 20
        self.lastError = nil
    }
    
    // MARK: - Countdown Loop
    
    private func startCountdown(for broadcastId: UUID, expiresAt: Date) {
        cancelTimer()
        
        countdownTask = Task { [weak self] in
            while true {
                guard let self = self else { return }
                guard !Task.isCancelled else { return }
                guard self.activeBroadcast?.id == broadcastId else { return }
                
                let remaining = max(0, Int(ceil(expiresAt.timeIntervalSince(self.clock.now))))
                self.remainingSeconds = remaining
                
                if remaining <= 0 {
                    // 20s deadline reached: mark broadcast as closed
                    if var broadcast = self.activeBroadcast, broadcast.status == .open {
                        broadcast.status = .closed
                        self.repository.updateBroadcast(broadcast)
                        self.activeBroadcast = broadcast
                    }
                    return
                }
                
                do {
                    try await self.clock.sleep(seconds: 1.0)
                } catch {
                    return
                }
            }
        }
    }
    
    private func cancelTimer() {
        countdownTask?.cancel()
        countdownTask = nil
    }
}
