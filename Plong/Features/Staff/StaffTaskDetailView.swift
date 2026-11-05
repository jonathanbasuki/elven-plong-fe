import SwiftUI

/// Staff Task Detail View matching sample/staff/taskdetail.svg and taskdetaildone.svg.
/// Conforms to Apple HIG for layout, accessibility, and action feedback.
public struct StaffTaskDetailView: View {
    public let task: TaskLogItem
    public let router: NavigationRouter
    public let coordinator: AssignmentCoordinator
    public let repository: MockCrowdFlowRepository
    public let syncService: TaskSyncServiceProtocol
    
    @State private var isCompleted: Bool = false
    
    public init(
        task: TaskLogItem,
        router: NavigationRouter,
        coordinator: AssignmentCoordinator,
        repository: MockCrowdFlowRepository,
        syncService: TaskSyncServiceProtocol = MultipeerTaskSyncService.shared
    ) {
        self.task = task
        self.router = router
        self.coordinator = coordinator
        self.repository = repository
        self.syncService = syncService
        _isCompleted = State(initialValue: task.status == .done)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Nav Bar with Back Action & Title/Subtitle
            TopNavBar(
                title: "Task Details",
                subtitle: task.title,
                titleSize: 18,
                leadingAction: .back {
                    router.pop()
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Task Header Summary Card (same TaskCard, no chevron)
                    TaskCard(
                        title: task.title,
                        timestamp: task.formattedDateTime,
                        statusStyle: isCompleted ? .done : .accepted
                    )
                    
                    // 2. Task Instruction & Location Card
                    TaskInstructionCard(task: task)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            
            // 3. Bottom "Completed" Action Button (Only when not yet completed)
            if !isCompleted {
                PrimaryPillButton(title: "Completed") {
                    markTaskCompleted()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.25), value: isCompleted)
    }
    
    // MARK: - Actions
    private func markTaskCompleted() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
        
        let zoneId = task.zoneID ?? MockDataConstants.zone1Id
        // Update repository: Pantry crowd drops to normal (15)
        if var zone = repository.getZone(by: zoneId) {
            zone.currentCount = 15
            repository.updateZone(zone)
        }
        
        // Finish coordinator broadcast
        try? coordinator.finishBroadcast()
        
        // Broadcast task completion to Manager device via P2P sync
        syncService.broadcastTaskCompleted(
            taskId: task.id,
            zoneId: zoneId,
            zoneCount: 15,
            totalCrowd: 45
        )
    }
}

#Preview {
    let repo = MockCrowdFlowRepository()
    let router = NavigationRouter()
    let coordinator = AssignmentCoordinator(repository: repo)
    
    return StaffTaskDetailView(
        task: TaskLogItem(
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing
        ),
        router: router,
        coordinator: coordinator,
        repository: repo
    )
}

