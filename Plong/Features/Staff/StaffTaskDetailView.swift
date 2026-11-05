import SwiftUI

/// Staff Task Detail View matching sample/staff/taskdetail.svg and taskdetaildone.svg.
/// Conforms to Apple HIG for layout, accessibility, and action feedback.
public struct StaffTaskDetailView: View {
    public let task: TaskLogItem
    public let router: NavigationRouter
    public let coordinator: AssignmentCoordinator
    public let repository: MockCrowdFlowRepository
    
    @State private var isCompleted: Bool = false
    
    public init(
        task: TaskLogItem,
        router: NavigationRouter,
        coordinator: AssignmentCoordinator,
        repository: MockCrowdFlowRepository
    ) {
        self.task = task
        self.router = router
        self.coordinator = coordinator
        self.repository = repository
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
                    // 1. Task Header Summary Card
                    taskHeaderCard
                    
                    // 2. Task Instruction & Location Card
                    instructionAndLocationCard
                    
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
    
    // MARK: - Task Header Summary Card
    private var taskHeaderCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(task.formattedDateTime)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            StatusPillBadge(style: isCompleted ? .done : .accepted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Instruction & Location Card
    private var instructionAndLocationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Task Instruction Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Instruction")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(task.instruction)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineSpacing(4)
            }
            
            // Location Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Location")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    
                    Text(task.locationName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                
                // Floor Plan Mini Map Preview
                miniMapCard
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Floor Plan Mini Map Snippet
    private var miniMapCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .systemGray6))
            
            // Denah Map Image
            Image("denah")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(12)
                .opacity(0.85)
            
            // Highlighted Zone Pin
            VStack(spacing: 2) {
                Image(systemName: "mappin")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.05, green: 0.49, blue: 0.95))
                    .shadow(radius: 2)
                
                Text(task.locationName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func markTaskCompleted() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
        
        // Update repository: Pantry crowd drops to normal (15)
        if var pantry = repository.getZone(by: MockDataConstants.zone1Id) {
            pantry.currentCount = 15
            repository.updateZone(pantry)
        }
        
        // Finish coordinator broadcast
        try? coordinator.finishBroadcast()
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

