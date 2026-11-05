import SwiftUI

/// Staff Home Screen matching sample/staff/tasklog1.svg and tasklog2.svg.
/// Staff view does not have the bottom floating tab bar (Staff only operates on Task Log).
public struct StaffHomeView: View {
    public let repository: MockCrowdFlowRepository
    public let coordinator: AssignmentCoordinator
    public let router: NavigationRouter
    public let syncService: TaskSyncServiceProtocol
    
    @State private var selectedSegment: TaskLogSegment = .ongoing
    @State private var completedTaskIDs: Set<UUID> = []
    @State private var dynamicTasks: [TaskLogItem] = []
    @State private var incomingAlertTask: TaskLogItem? = nil
    
    // Seed staff tasks matching sample/staff/
    private let initialOngoingTask = TaskLogItem(
        id: UUID(uuidString: "f1000000-0000-0000-0000-000000000001")!,
        title: "Overflow in Pantry",
        dateString: "3 October 2026",
        timeString: "14:05",
        status: .ongoing,
        zoneID: MockDataConstants.zone1Id,
        instruction: "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan",
        locationName: "Pantry"
    )
    
    private let initialHistoryTask = TaskLogItem(
        id: UUID(uuidString: "f1000000-0000-0000-0000-000000000002")!,
        title: "Overflow in Lab 2",
        dateString: "1 October 2026",
        timeString: "13:12",
        status: .done,
        zoneID: MockDataConstants.zone2Id,
        instruction: "Pastikan passenger tertib tidak ada maling barang-barang semua aman tidak anak anak nangis dan semua enjoy dalam perjalanan",
        locationName: "Lab 2"
    )
    
    public init(
        repository: MockCrowdFlowRepository,
        coordinator: AssignmentCoordinator,
        syncService: TaskSyncServiceProtocol = MultipeerTaskSyncService.shared,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.coordinator = coordinator
        self.syncService = syncService
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Persistent Top Nav Bar with Staff Profile & Logout Menu
            TopNavBar(
                title: "Task Log",
                titleSize: 24,
                onLogout: {
                    logout()
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 12)
            
            // Segmented Capsule [ Ongoing | History ]
            segmentedControl
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Staff Tasks List
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    let items = currentTasks
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(items) { task in
                            staffTaskCard(task)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
        .fullScreenCover(item: $incomingAlertTask) { alertTask in
            StaffTaskAlertView(
                task: alertTask,
                onAccept: { acceptedTask in
                    if !dynamicTasks.contains(where: { $0.id == acceptedTask.id }) {
                        dynamicTasks.insert(acceptedTask, at: 0)
                    }
                    incomingAlertTask = nil
                    router.navigate(to: .staffTaskDetail(item: acceptedTask))
                },
                onDismiss: {
                    incomingAlertTask = nil
                }
            )
        }
        .onAppear {
            setupSync()
        }
    }
    
    private func setupSync() {
        syncService.onTaskDispatched = { newTask in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                self.incomingAlertTask = newTask
            }
        }
    }
    
    // MARK: - Current Tasks based on segment and completion
    private var currentTasks: [TaskLogItem] {
        let isPantryDone = completedTaskIDs.contains(initialOngoingTask.id) ||
                           coordinator.activeBroadcast?.status == .finished ||
                           (repository.getZone(by: MockDataConstants.zone1Id)?.currentCount ?? 50) <= 20
        
        switch selectedSegment {
        case .ongoing:
            var items: [TaskLogItem] = []
            for dyn in dynamicTasks where !completedTaskIDs.contains(dyn.id) && dyn.status == .ongoing {
                items.append(dyn)
            }
            if !isPantryDone && !items.contains(where: { $0.id == initialOngoingTask.id }) {
                items.append(initialOngoingTask)
            }
            return items
            
        case .history:
            var items: [TaskLogItem] = []
            for var dyn in dynamicTasks where completedTaskIDs.contains(dyn.id) || dyn.status == .done {
                dyn.status = .done
                items.append(dyn)
            }
            if isPantryDone {
                var donePantry = initialOngoingTask
                donePantry.status = .done
                items.append(donePantry)
            }
            items.append(initialHistoryTask)
            return items
        }
    }
    
    // MARK: - Segmented Capsule [ Ongoing | History ]
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Ongoing", isSelected: selectedSegment == .ongoing) {
                selectedSegment = .ongoing
            }
            
            segmentButton(title: "History", isSelected: selectedSegment == .history) {
                selectedSegment = .history
            }
        }
        .padding(3)
        .background(Color(uiColor: .systemGray6))
        .clipShape(Capsule())
    }
    
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color(uiColor: .systemBackground) : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) staff tasks")
    }
    
    // MARK: - Staff Task Card matching sample/staff/tasklog1.svg & tasklog2.svg
    private func staffTaskCard(_ task: TaskLogItem) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            router.navigate(to: .staffTaskDetail(item: task))
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(uiColor: .label))
                        .multilineTextAlignment(.leading)
                    
                    Text(task.formattedDateTime)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    StatusPillBadge(style: task.status == .ongoing ? .accepted : .done)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(task.formattedDateTime), Status: \(task.status == .ongoing ? "Accepted" : "Done")")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 40))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                .padding(.top, 40)
            
            Text("No \(selectedSegment.rawValue) Tasks")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func logout() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        router.logout()
    }
}

#Preview {
    let repo = MockCrowdFlowRepository()
    let router = NavigationRouter(isAuthenticated: true, currentUserRole: .staff)
    let coordinator = AssignmentCoordinator(repository: repo)
    
    return StaffHomeView(
        repository: repo,
        coordinator: coordinator,
        router: router
    )
}

