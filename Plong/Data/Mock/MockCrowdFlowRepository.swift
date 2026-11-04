import Foundation
import Observation

public struct MockDataConstants {
    public static let zone1Id = "z1"
    public static let zone2Id = "z2"
    public static let zone3Id = "z3"
    public static let zone4Id = "z4"
    
    // Stable seed UUIDs from seed.sql
    public static let staffAldiId = UUID(uuidString: "a1111111-0000-0000-0000-000000000001")!
    public static let staffBungaId = UUID(uuidString: "a1111111-0000-0000-0000-000000000002")!
    public static let staffCitraId = UUID(uuidString: "a1111111-0000-0000-0000-000000000003")!
    public static let staffDediId = UUID(uuidString: "a1111111-0000-0000-0000-000000000004")!
    public static let staffEkaId = UUID(uuidString: "a1111111-0000-0000-0000-000000000005")!
    
    // Backwards compatibility aliases
    public static let zoneAId = zone1Id
    public static let zoneBId = zone2Id
    public static let zoneCId = zone3Id
    public static let zoneDId = zone4Id
    public static let staffMarcusId = staffAldiId
    public static let staffSarahId = staffBungaId
    public static let staffAlexId = staffCitraId
    public static let staffDavidId = staffDediId
    public static let staffElenaId = staffEkaId
}

@Observable
@MainActor
public final class MockCrowdFlowRepository: CrowdFlowRepositoryProtocol {
    public var zones: [VenueZone] = []
    public var staffMembers: [SecurityStaff] = []
    public var broadcasts: [BroadcastSession] = []
    public var alerts: [CrowdAlert] = []
    public var assignmentRequests: [AssignmentRequest] = []
    public var confirmedAssignments: [ConfirmedAssignment] = []
    public var clock: ClockProtocol
    
    public init(clock: ClockProtocol) {
        self.clock = clock
        resetToDefaults()
    }
    
    public convenience init() {
        self.init(clock: SystemClock())
    }
    
    public func resetToDefaults() {
        // Staff seed matching seed.sql exactly
        let initialStaff1 = SecurityStaff(
            id: MockDataConstants.staffAldiId,
            name: "Aldi",
            status: .idle,
            pushToken: "apns-token-aldi",
            currentZoneID: MockDataConstants.zone1Id,
            mockDistancesToZones: [MockDataConstants.zone1Id: 5.0, MockDataConstants.zone2Id: 15.0]
        )
        
        let initialStaff2 = SecurityStaff(
            id: MockDataConstants.staffBungaId,
            name: "Bunga",
            status: .idle,
            pushToken: "apns-token-bunga",
            currentZoneID: MockDataConstants.zone1Id,
            mockDistancesToZones: [MockDataConstants.zone1Id: 10.0, MockDataConstants.zone2Id: 25.0]
        )
        
        let initialStaff3 = SecurityStaff(
            id: MockDataConstants.staffCitraId,
            name: "Citra",
            status: .idle,
            pushToken: "apns-token-citra",
            currentZoneID: MockDataConstants.zone2Id,
            mockDistancesToZones: [MockDataConstants.zone1Id: 20.0, MockDataConstants.zone2Id: 8.0]
        )
        
        let initialStaff4 = SecurityStaff(
            id: MockDataConstants.staffDediId,
            name: "Dedi",
            status: .idle,
            pushToken: "apns-token-dedi",
            currentZoneID: MockDataConstants.zone3Id,
            mockDistancesToZones: [MockDataConstants.zone1Id: 30.0, MockDataConstants.zone2Id: 18.0]
        )
        
        let initialStaff5 = SecurityStaff(
            id: MockDataConstants.staffEkaId,
            name: "Eka",
            status: .idle,
            pushToken: "apns-token-eka",
            currentZoneID: MockDataConstants.zone4Id,
            mockDistancesToZones: [MockDataConstants.zone1Id: 40.0, MockDataConstants.zone2Id: 32.0]
        )
        
        let additionalNames = [
            "Farhan", "Gita", "Hadi", "Intan", "Joko",
            "Kevin", "Lina", "Maya", "Niko", "Putri",
            "Rizky", "Siti", "Taufik"
        ]
        
        var allStaff = [
            initialStaff1,
            initialStaff2,
            initialStaff3,
            initialStaff4,
            initialStaff5
        ]
        
        for (index, name) in additionalNames.enumerated() {
            let staff = SecurityStaff(
                id: UUID(uuidString: String(format: "a1111111-0000-0000-0000-%012d", index + 6))!,
                name: name,
                status: index < 2 ? .idle : .delegating,
                pushToken: "apns-token-\(name.lowercased())",
                currentZoneID: MockDataConstants.zone1Id,
                mockDistancesToZones: [MockDataConstants.zone1Id: Double(index * 5)]
            )
            allStaff.append(staff)
        }
        
        self.staffMembers = allStaff
        
        // Zones seed: Matches sample/overview.svg and modal detail zone.svg
        // Zone 1: Pantry Academy (50 occupants, Overflowed)
        // Zone 2: Collab Area (20 occupants)
        // Zone 3: Meeting & Pods (10 occupants)
        // Total Crowd: 80 occupants | Active Staff: 18
        self.zones = [
            VenueZone(
                id: MockDataConstants.zone1Id,
                name: "Pantry Academy",
                currentCount: 50, // Warning threshold = 20, crowded = 35 -> status: crowded ("Overflowed")
                warningThreshold: 20,
                crowdedThreshold: 35,
                mapImageUrl: "denah",
                polygon: [
                    [0.1677, 0.5065],
                    [0.4682, 0.437],
                    [0.9917, 0.6481],
                    [0.9958, 0.9435],
                    [0.1682, 0.512]
                ],
                assignedStaffIDs: [MockDataConstants.staffAldiId, MockDataConstants.staffBungaId]
            ),
            VenueZone(
                id: MockDataConstants.zone2Id,
                name: "Collab Area",
                currentCount: 20,
                warningThreshold: 15,
                crowdedThreshold: 30,
                mapImageUrl: "denah",
                polygon: [
                    [0.2, 0.2],
                    [0.8, 0.2],
                    [0.8, 0.8],
                    [0.2, 0.8]
                ],
                assignedStaffIDs: []
            ),
            VenueZone(
                id: MockDataConstants.zone3Id,
                name: "Meeting & Pods",
                currentCount: 10,
                warningThreshold: 10,
                crowdedThreshold: 25,
                mapImageUrl: "denah",
                polygon: [
                    [0.1, 0.1],
                    [0.9, 0.1],
                    [0.9, 0.5],
                    [0.1, 0.5]
                ],
                assignedStaffIDs: []
            )
        ]
        
        self.alerts = [
            CrowdAlert(
                id: UUID(),
                zoneID: MockDataConstants.zone1Id,
                alertType: .crowdDensityIncreasing,
                title: "Threshold Warning",
                message: "Main Lobby reached 7 people (warning threshold: 5). Staff delegation recommended.",
                createdAt: Date().addingTimeInterval(-180),
                isRead: false
            ),
            CrowdAlert(
                id: UUID(),
                zoneID: MockDataConstants.zone2Id,
                alertType: .highCrowdDetected,
                title: "Crowd Surge",
                message: "West Plaza is crowded with 12 people exceeding the threshold (10).",
                createdAt: Date().addingTimeInterval(-60),
                isRead: false
            )
        ]
        
        self.broadcasts = []
        self.assignmentRequests = []
        self.confirmedAssignments = []
    }
    
    // MARK: - Querying
    
    public func getZone(by id: String) -> VenueZone? {
        zones.first { $0.id == id }
    }
    
    public func getStaff(by id: UUID) -> SecurityStaff? {
        staffMembers.first { $0.id == id }
    }
    
    public func getCurrentBroadcast(for zoneId: String) -> BroadcastSession? {
        // Return active open or closed broadcast, most recent first
        broadcasts
            .filter { $0.zoneId == zoneId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    public func getBroadcast(by id: UUID) -> BroadcastSession? {
        broadcasts.first { $0.id == id }
    }
    
    // MARK: - Contract Operations
    
    public func createBroadcast(zoneId: String, staffNeeded: Int) throws -> BroadcastSession {
        // 1. 409 broadcast_open if a broadcast with status = 'open' already exists for this zoneId
        if broadcasts.contains(where: { $0.zoneId == zoneId && $0.status == .open }) {
            throw BroadcastError.broadcastOpen("A broadcast is already open for zone \(zoneId).")
        }
        
        guard let zone = getZone(by: zoneId) else {
            throw BroadcastError.notFound("Zone \(zoneId) not found.")
        }
        
        // 2. Insert the row, expiresAt = now() + 20s
        let session = BroadcastSession(
            id: UUID(),
            zoneId: zoneId,
            staffNeeded: staffNeeded,
            status: .open,
            createdAt: clock.now,
            expiresAt: clock.now.addingTimeInterval(20.0),
            finishedAt: nil,
            acceptedStaff: []
        )
        
        broadcasts.insert(session, at: 0)
        
        // 3. Emit Alert (simulating push to all staff)
        addAlert(CrowdAlert(
            zoneID: zoneId,
            alertType: .securityBroadcastSent,
            title: "Broadcast Dispatched",
            message: "Dispatched to all staff for \(zone.name) (\(staffNeeded) needed).",
            createdAt: clock.now,
            relatedRequestID: session.id
        ))
        
        return session
    }
    
    public func respondToBroadcast(broadcastId: UUID, staffId: UUID) throws {
        // 1. 404 not_found if broadcast doesn't exist
        guard let bIndex = broadcasts.firstIndex(where: { $0.id == broadcastId }) else {
            throw BroadcastError.notFound("Broadcast not found.")
        }
        guard let staff = getStaff(by: staffId) else {
            throw BroadcastError.notFound("Staff member not found.")
        }
        
        var broadcast = broadcasts[bIndex]
        
        // Check if already responded
        if broadcast.acceptedStaff.contains(where: { $0.staffId == staffId }) {
            return // idempotent
        }
        
        // 2. 409 expired if now() > expires_at
        if clock.now > broadcast.expiresAt || broadcast.status != .open {
            broadcast.status = .closed
            broadcasts[bIndex] = broadcast
            throw BroadcastError.expired("This broadcast has expired.")
        }
        
        // 3. 409 slots_full if acceptedCount >= staff_needed
        if broadcast.acceptedCount >= broadcast.staffNeeded {
            throw BroadcastError.slotsFull("This broadcast already has enough staff.")
        }
        
        // 4. Insert response row, set staff.status = 'delegating'
        let acceptedItem = AcceptedStaffItem(
            staffId: staffId,
            name: staff.name,
            respondedAt: clock.now,
            completedAt: nil
        )
        broadcast.acceptedStaff.append(acceptedItem)
        broadcasts[bIndex] = broadcast
        
        var updatedStaff = staff
        updatedStaff.status = .delegating
        updateStaff(updatedStaff)
        
        // Add alert
        let zoneName = getZone(by: broadcast.zoneId)?.name ?? broadcast.zoneId
        addAlert(CrowdAlert(
            zoneID: broadcast.zoneId,
            alertType: .assignmentAccepted,
            title: "Staff Accepted Broadcast",
            message: "\(staff.name) accepted delegation to \(zoneName).",
            createdAt: clock.now,
            relatedRequestID: broadcast.id
        ))
    }
    
    public func completeBroadcast(broadcastId: UUID, staffId: UUID) throws {
        // 1. 404 not_found
        guard let bIndex = broadcasts.firstIndex(where: { $0.id == broadcastId }) else {
            throw BroadcastError.notFound("Broadcast not found.")
        }
        var broadcast = broadcasts[bIndex]
        
        // 2. 403 not_your_response if no response row exists
        guard let sIndex = broadcast.acceptedStaff.firstIndex(where: { $0.staffId == staffId }) else {
            throw BroadcastError.notYourResponse("Staff member never accepted this broadcast.")
        }
        
        // 3. Set completed_at = now(), set staff.status = 'idle'
        var item = broadcast.acceptedStaff[sIndex]
        item.completedAt = clock.now
        broadcast.acceptedStaff[sIndex] = item
        broadcasts[bIndex] = broadcast
        
        if var staff = getStaff(by: staffId) {
            staff.status = .idle
            updateStaff(staff)
        }
    }
    
    public func finishBroadcast(broadcastId: UUID) throws -> BroadcastSession {
        guard let bIndex = broadcasts.firstIndex(where: { $0.id == broadcastId }) else {
            throw BroadcastError.notFound("Broadcast not found.")
        }
        var broadcast = broadcasts[bIndex]
        
        // 409 not_all_done unless acceptedCount >= 1 AND completedCount == acceptedCount
        guard broadcast.acceptedCount >= 1 && broadcast.completedCount == broadcast.acceptedCount else {
            throw BroadcastError.notAllDone("Cannot finish: all accepted staff must complete delegation first.")
        }
        
        broadcast.status = .finished
        broadcast.finishedAt = clock.now
        broadcasts[bIndex] = broadcast
        
        let zoneName = getZone(by: broadcast.zoneId)?.name ?? broadcast.zoneId
        addAlert(CrowdAlert(
            zoneID: broadcast.zoneId,
            alertType: .assignmentAccepted,
            title: "Delegation Completed",
            message: "Broadcast for \(zoneName) finished successfully.",
            createdAt: Date(),
            relatedRequestID: broadcast.id
        ))
        
        return broadcast
    }
    
    // MARK: - Mutators
    
    public func updateZone(_ zone: VenueZone) {
        if let index = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[index] = zone
        } else {
            zones.append(zone)
        }
    }
    
    public func updateStaff(_ staff: SecurityStaff) {
        if let index = staffMembers.firstIndex(where: { $0.id == staff.id }) {
            staffMembers[index] = staff
        } else {
            staffMembers.append(staff)
        }
    }
    
    public func updateBroadcast(_ session: BroadcastSession) {
        if let index = broadcasts.firstIndex(where: { $0.id == session.id }) {
            broadcasts[index] = session
        } else {
            broadcasts.insert(session, at: 0)
        }
    }
    
    public func addAlert(_ alert: CrowdAlert) {
        let isDuplicate = alerts.contains {
            $0.alertType == alert.alertType &&
            $0.zoneID == alert.zoneID &&
            abs($0.createdAt.timeIntervalSince(alert.createdAt)) < 5.0
        }
        if !isDuplicate {
            alerts.insert(alert, at: 0)
        }
    }
    
    public func markAlertAsRead(id: UUID) {
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].isRead = true
        }
    }
    
    // MARK: - Legacy Compatibility
    
    public func getAssignmentRequest(by id: UUID) -> AssignmentRequest? {
        assignmentRequests.first { $0.id == id }
    }
    
    public func getConfirmedAssignment(by requestID: UUID) -> ConfirmedAssignment? {
        confirmedAssignments.first { $0.requestID == requestID }
    }
    
    public func addAssignmentRequest(_ request: AssignmentRequest) {
        assignmentRequests.append(request)
    }
    
    public func updateAssignmentRequest(_ request: AssignmentRequest) {
        if let index = assignmentRequests.firstIndex(where: { $0.id == request.id }) {
            assignmentRequests[index] = request
        } else {
            assignmentRequests.append(request)
        }
    }
    
    public func addConfirmedAssignment(_ assignment: ConfirmedAssignment) {
        confirmedAssignments.append(assignment)
    }
    
    public func updateConfirmedAssignment(_ assignment: ConfirmedAssignment) {
        if let index = confirmedAssignments.firstIndex(where: { $0.id == assignment.id }) {
            confirmedAssignments[index] = assignment
        } else {
            confirmedAssignments.append(assignment)
        }
    }
}
