import Foundation
import Observation

public enum TaskLogSegment: String, CaseIterable, Identifiable, Sendable {
    case ongoing = "Ongoing"
    case history = "History"
    
    public var id: String { rawValue }
}

@Observable
@MainActor
public final class TaskLogViewModel {
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    
    public var selectedSegment: TaskLogSegment = .ongoing
    public var showProfileSheet: Bool = false
    
    // Seed matching sample/Manager/tasklog1.svg and tasklog2.svg exactly
    private var ongoingLogs: [TaskLogItem] = [
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000001")!,
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing,
            zoneID: MockDataConstants.zone1Id,
            instruction: "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan",
            locationName: "Pantry"
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000002")!,
            title: "Overflow in Lab 2",
            dateString: "3 October 2026",
            timeString: "13:15",
            status: .ongoing,
            zoneID: MockDataConstants.zone2Id,
            instruction: "Monitor pintu masuk Lab 2 dan pastikan aliran keluar masuk tertib.",
            locationName: "Lab 2"
        )
    ]
    
    private var historyLogs: [TaskLogItem] = [
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000003")!,
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .done,
            zoneID: MockDataConstants.zone1Id,
            instruction: "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan",
            locationName: "Pantry"
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000004")!,
            title: "Overflow in Lab 2",
            dateString: "1 October 2026",
            timeString: "13:15",
            status: .done,
            zoneID: MockDataConstants.zone2Id,
            instruction: "Monitor pintu masuk Lab 2 dan pastikan aliran keluar masuk tertib.",
            locationName: "Lab 2"
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000005")!,
            title: "Overflow in Lab 1",
            dateString: "29 September 2026",
            timeString: "15:09",
            status: .done,
            zoneID: MockDataConstants.zone3Id,
            instruction: "Pastikan kepadatan di Lab 1 terkontrol.",
            locationName: "Lab 1"
        )
    ]
    
    public init(
        repository: CrowdFlowRepositoryProtocol,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.router = router
    }
    
    public var taskLogs: [TaskLogItem] {
        switch selectedSegment {
        case .ongoing:
            var list = ongoingLogs
            // Dynamically inject any open broadcasts from repo
            for b in repository.broadcasts where b.status == .open {
                let zoneName = repository.getZone(by: b.zoneId)?.name ?? "Zone \(b.zoneId)"
                if !list.contains(where: { $0.id == b.id }) {
                    list.insert(TaskLogItem(
                        id: b.id,
                        title: "Overflow in \(zoneName)",
                        dateString: "Today",
                        timeString: "Now",
                        status: .ongoing,
                        zoneID: b.zoneId
                    ), at: 0)
                }
            }
            return list
            
        case .history:
            var list = historyLogs
            // Dynamically inject any finished broadcasts
            for b in repository.broadcasts where b.status == .finished {
                let zoneName = repository.getZone(by: b.zoneId)?.name ?? "Zone \(b.zoneId)"
                if !list.contains(where: { $0.id == b.id }) {
                    list.insert(TaskLogItem(
                        id: b.id,
                        title: "Overflow in \(zoneName)",
                        dateString: "Today",
                        timeString: "Done",
                        status: .done,
                        zoneID: b.zoneId
                    ), at: 0)
                }
            }
            return list
        }
    }
    
    #if DEBUG
    /// Debug-only: inserts a randomized mock task at the top of the Ongoing list.
    public func addMockOngoingTask() {
        let locations: [(name: String, zoneID: String)] = [
            ("Pantry", MockDataConstants.zone1Id),
            ("Lab 2", MockDataConstants.zone2Id),
            ("Lab 1", MockDataConstants.zone3Id)
        ]
        let location = locations.randomElement()!
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        ongoingLogs.insert(
            TaskLogItem(
                title: "Overflow in \(location.name)",
                dateString: dateFormatter.string(from: now),
                timeString: timeFormatter.string(from: now),
                status: .ongoing,
                zoneID: location.zoneID,
                instruction: "[Mock] Pantau kepadatan di \(location.name) dan arahkan pengunjung agar tertib.",
                locationName: location.name
            ),
            at: 0
        )
    }
    #endif

    public func selectTask(_ task: TaskLogItem) {
        router.navigate(to: .taskDetail(item: task))
    }
    
    public func openOverview() {
        router.popToRoot()
    }
    
    public func logout() {
        showProfileSheet = false
        router.isAuthenticated = false
        router.popToRoot()
    }
}
