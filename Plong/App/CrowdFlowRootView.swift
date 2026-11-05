import SwiftUI

@MainActor
public struct CrowdFlowRootView: View {
    @State private var router: NavigationRouter
    @State private var repository: MockCrowdFlowRepository
    @State private var coordinator: AssignmentCoordinator
    @State private var syncService: TaskSyncServiceProtocol
    
    public init() {
        let repo = MockCrowdFlowRepository()
        let router = NavigationRouter()
        _repository = State(initialValue: repo)
        _router = State(initialValue: router)
        _coordinator = State(initialValue: AssignmentCoordinator(repository: repo))
        _syncService = State(initialValue: MultipeerTaskSyncService.shared)
    }
    
    public init(
        repository: MockCrowdFlowRepository,
        router: NavigationRouter,
        syncService: TaskSyncServiceProtocol = MultipeerTaskSyncService.shared
    ) {
        _repository = State(initialValue: repository)
        _router = State(initialValue: router)
        _coordinator = State(initialValue: AssignmentCoordinator(repository: repository))
        _syncService = State(initialValue: syncService)
    }
    
    public var body: some View {
        Group {
            if !router.isAuthenticated {
                LoginView(viewModel: LoginViewModel(router: router))
            } else {
                NavigationStack(path: $router.path) {
                    Group {
                        if router.currentUserRole == .manager {
                            ManagerHomeView(
                                repository: repository,
                                coordinator: coordinator,
                                syncService: syncService,
                                router: router
                            )
                        } else {
                            StaffHomeView(
                                repository: repository,
                                coordinator: coordinator,
                                syncService: syncService,
                                router: router
                            )
                        }
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            if router.isAuthenticated {
                syncService.start(as: router.currentUserRole)
            }
        }
        .onChange(of: router.isAuthenticated) { _, isAuth in
            if isAuth {
                syncService.start(as: router.currentUserRole)
            } else {
                syncService.stop()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .crowdMap, .taskLog:
            if router.currentUserRole == .manager {
                ManagerHomeView(
                    repository: repository,
                    coordinator: coordinator,
                    syncService: syncService,
                    router: router
                )
            } else {
                StaffHomeView(
                    repository: repository,
                    coordinator: coordinator,
                    syncService: syncService,
                    router: router
                )
            }
            
        case .taskDetail(let item):
            TaskDetailView(
                task: item,
                router: router
            )
            
        case .staffTaskDetail(let item):
            StaffTaskDetailView(
                task: item,
                router: router,
                coordinator: coordinator,
                repository: repository,
                syncService: syncService
            )
        }
    }
}

#Preview {
    CrowdFlowRootView()
}
