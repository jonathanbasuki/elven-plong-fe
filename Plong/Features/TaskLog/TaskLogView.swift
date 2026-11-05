import SwiftUI

/// Task Log View matching sample/Manager/Task log.svg and sample/sort status.svg.
/// Conforms to Apple HIG for navigation, lists, and menus.
public struct TaskLogView: View {
    @Bindable var viewModel: TaskLogViewModel
    public var showChrome: Bool = false
    
    public init(viewModel: TaskLogViewModel, showChrome: Bool = false) {
        self.viewModel = viewModel
        self.showChrome = showChrome
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if showChrome {
                    TopNavBar(title: "Task Log", onLogout: {
                        viewModel.logout()
                    })
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
                
                // Segmented Capsule [ Ongoing | History ] matching tasklog1.svg & tasklog2.svg
                segmentedControl
                    .padding(.horizontal, 20)
                    .padding(.top, showChrome ? 0 : 8)
                    .padding(.bottom, 16)

                #if DEBUG
                if viewModel.selectedSegment == .ongoing {
                    debugMockTaskButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                #endif

                // Tasks List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.taskLogs) { task in
                            taskCard(task)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, showChrome ? 100 : 80) // Clearance for floating bar
                }
            }
            
            if showChrome {
                FloatingTabBar(activeTab: .taskLog) { tab in
                    if tab == .overview {
                        viewModel.openOverview()
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
    }
    
    #if DEBUG
    // MARK: - Debug: Mock Task Generator
    private var debugMockTaskButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.addMockOngoingTask()
            }
        } label: {
            Label("Add Mock Task (Debug)", systemImage: "ladybug")
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .clipShape(Capsule())
        .accessibilityLabel("Add mock ongoing task")
    }
    #endif

    // MARK: - Segmented Capsule [ Ongoing | History ]
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Ongoing", isSelected: viewModel.selectedSegment == .ongoing) {
                viewModel.selectedSegment = .ongoing
            }
            
            segmentButton(title: "History", isSelected: viewModel.selectedSegment == .history) {
                viewModel.selectedSegment = .history
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
        .accessibilityLabel("\(title) tasks")
    }
    
    // MARK: - Task Card matching sample/Manager/Task log.svg
    @ViewBuilder
    private func taskCard(_ task: TaskLogItem) -> some View {
        TaskCard(task: task, ongoingStyle: .ongoing) {
            viewModel.selectTask(task)
        }
    }
}

#Preview {
    TaskLogView(
        viewModel: TaskLogViewModel(
            repository: MockCrowdFlowRepository(),
            router: NavigationRouter()
        ),
        showChrome: true
    )
}
