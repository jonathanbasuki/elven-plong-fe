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
                    CrowdMapView(viewModel: CrowdMapViewModel(repository: repository, router: router))
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .crowdMap:
            CrowdMapView(
                viewModel: CrowdMapViewModel(
                    repository: repository,
                    router: router
                )
            )
            
        case .zoneDetail(let zoneID):
            ZoneDetailView(
                viewModel: ZoneDetailViewModel(
                    zoneID: zoneID,
                    repository: repository,
                    coordinator: coordinator,
                    router: router
                )
            )
            
        case .createBroadcast(let zoneID):
            CreateBroadcastView(
                viewModel: CreateBroadcastViewModel(
                    zoneID: zoneID,
                    repository: repository,
                    coordinator: coordinator,
                    router: router
                )
            )
            
        case .broadcast(let zoneID):
            BroadcastView(
                viewModel: BroadcastViewModel(
                    zoneID: zoneID,
                    repository: repository,
                    coordinator: coordinator,
                    router: router
                )
            )
            
        case .assignmentStatus(let requestID):
            AssignmentStatusView(
                viewModel: AssignmentStatusViewModel(
                    requestID: requestID,
                    repository: repository,
                    router: router
                )
            )
            
        case .alerts:
            AlertsView(
                viewModel: AlertsViewModel(
                    repository: repository,
                    router: router
                )
            )
        }
    }
}
