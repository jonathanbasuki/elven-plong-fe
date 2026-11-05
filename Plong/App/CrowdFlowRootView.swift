import SwiftUI

@MainActor
public struct CrowdFlowRootView: View {
    @State private var router: NavigationRouter
    @State private var repository: MockCrowdFlowRepository
    @State private var coordinator: AssignmentCoordinator
    
    public init() {
        let defaultRepo = MockCrowdFlowRepository()
        let defaultRouter = NavigationRouter()
        _repository = State(initialValue: defaultRepo)
        _router = State(initialValue: defaultRouter)
        _coordinator = State(initialValue: AssignmentCoordinator(repository: defaultRepo))
    }
    
    public init(
        repository: MockCrowdFlowRepository,
        router: NavigationRouter
    ) {
        _repository = State(initialValue: repository)
        _router = State(initialValue: router)
        _coordinator = State(initialValue: AssignmentCoordinator(repository: repository))
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
                                router: router
                            )
                        } else {
                            StaffHomeView(
                                repository: repository,
                                coordinator: coordinator,
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
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .crowdMap, .taskLog:
            if router.currentUserRole == .manager {
                ManagerHomeView(
                    repository: repository,
                    coordinator: coordinator,
                    router: router
                )
            } else {
                StaffHomeView(
                    repository: repository,
                    coordinator: coordinator,
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
                repository: repository
            )
        }
    }
}

#Preview {
    CrowdFlowRootView()
}
