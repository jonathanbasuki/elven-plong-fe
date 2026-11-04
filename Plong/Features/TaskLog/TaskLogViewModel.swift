import Foundation
import Observation

public enum TaskLogSortOrder: String, CaseIterable, Identifiable, Sendable {
    case latest = "Latest"
    case oldest = "Oldest"
    
    public var id: String { rawValue }
}

public enum TaskLogStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case ongoing = "Ongoing"
    case history = "History"
    
    public var id: String { rawValue }
}

@Observable
@MainActor
public final class TaskLogViewModel {
    public let repository: CrowdFlowRepositoryProtocol
    public let router: NavigationRouter
    
    public var selectedSort: TaskLogSortOrder = .latest
    public var selectedStatusFilter: TaskLogStatusFilter = .all
    public var showProfileSheet: Bool = false
    
    // Demo seed matching sample/Manager/Task log.svg exactly
    private var staticLogs: [TaskLogItem] = [
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000001")!,
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing,
            zoneID: MockDataConstants.zone1Id
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000002")!,
            title: "Overflow in Lab 2",
            dateString: "3 October 2026",
            timeString: "13:15",
            status: .ongoing,
            zoneID: MockDataConstants.zone2Id
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000003")!,
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "11:00",
            status: .done,
            zoneID: MockDataConstants.zone1Id
        ),
        TaskLogItem(
            id: UUID(uuidString: "e1000000-0000-0000-0000-000000000004")!,
            title: "Overflow in Lab 2",
            dateString: "3 October 2026",
            timeString: "12:05",
            status: .done,
            zoneID: MockDataConstants.zone2Id
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
        var result = staticLogs
        
        // Dynamically include real broadcasts from repository session if any
        let broadcasts = repository.broadcasts
        for b in broadcasts {
            let zoneName = repository.getZone(by: b.zoneId)?.name ?? "Zone \(b.zoneId)"
            let status: TaskLogStatus = (b.status == .finished) ? .done : .ongoing
            
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            let dateStr = formatter.string(from: b.createdAt)
            let timeStr = timeFormatter.string(from: b.createdAt)
            
            if !result.contains(where: { $0.id == b.id }) {
                let dynamicItem = TaskLogItem(
                    id: b.id,
                    title: "Overflow in \(zoneName)",
                    dateString: dateStr,
                    timeString: timeStr,
                    status: status,
                    zoneID: b.zoneId
                )
                result.insert(dynamicItem, at: 0)
            }
        }
        
        // Status filter
        switch selectedStatusFilter {
        case .all:
            break
        case .ongoing:
            result = result.filter { $0.status == .ongoing }
        case .history:
            result = result.filter { $0.status == .done }
        }
        
        // Sort order
        if selectedSort == .oldest {
            result.reverse()
        }
        
        return result
    }
    
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
