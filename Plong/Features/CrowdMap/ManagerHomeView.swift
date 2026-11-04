import SwiftUI

/// Persistent Manager Home Container conforming to Apple HIG.
/// Keeps the Top Navigation Bar and Bottom Floating Tab Bar permanently in place,
/// updating the content behind them smoothly without whole-page navigation jumps.
public struct ManagerHomeView: View {
    public let repository: MockCrowdFlowRepository
    public let coordinator: AssignmentCoordinator
    public let router: NavigationRouter
    
    @State private var selectedTab: MainTab = .overview
    @State private var crowdMapViewModel: CrowdMapViewModel
    @State private var taskLogViewModel: TaskLogViewModel
    
    public init(
        repository: MockCrowdFlowRepository,
        coordinator: AssignmentCoordinator,
        router: NavigationRouter
    ) {
        self.repository = repository
        self.coordinator = coordinator
        self.router = router
        
        _crowdMapViewModel = State(initialValue: CrowdMapViewModel(
            repository: repository,
            coordinator: coordinator,
            router: router
        ))
        _taskLogViewModel = State(initialValue: TaskLogViewModel(
            repository: repository,
            router: router
        ))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Persistent Top Navigation Bar
            TopNavBar(
                title: selectedTab == .overview ? "Overview" : "Task Log",
                titleSize: 24,
                onLogout: {
                    logout()
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 4)
            .background(Color(uiColor: .systemBackground))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // 2. Dynamic Content Area with Persistent Floating Tab Bar
            ZStack(alignment: .bottom) {
                // In-place Content Switch (Zero whole-page navigation push)
                Group {
                    if selectedTab == .overview {
                        CrowdMapView(viewModel: crowdMapViewModel, showChrome: false)
                            .transition(.opacity)
                    } else {
                        TaskLogView(viewModel: taskLogViewModel, showChrome: false)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                
                // 3. Persistent Floating Tab Bar
                FloatingTabBar(activeTab: selectedTab) { newTab in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = newTab
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
    }
    
    private func logout() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        router.isAuthenticated = false
        router.popToRoot()
    }
}

#Preview {
    let repo = MockCrowdFlowRepository()
    let router = NavigationRouter(isAuthenticated: true)
    let coordinator = AssignmentCoordinator(repository: repo)
    
    return NavigationStack {
        ManagerHomeView(
            repository: repo,
            coordinator: coordinator,
            router: router
        )
    }
}

