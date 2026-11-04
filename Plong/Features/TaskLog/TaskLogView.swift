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
                
                // Subheader with "Task" and Sort/Status Menu
                subHeader
                    .padding(.horizontal, 20)
                    .padding(.top, showChrome ? 0 : 8)
                    .padding(.bottom, 14)
                
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
    
    // MARK: - Subheader with Multi-Section Sort/Status Menu
    private var subHeader: some View {
        HStack {
            Text("Task")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(uiColor: .label))
            
            Spacer()
            
            // Menu matching sample/sort status.svg
            Menu {
                Section("Sort") {
                    Button {
                        viewModel.selectedSort = .latest
                    } label: {
                        if viewModel.selectedSort == .latest {
                            Label("Latest", systemImage: "checkmark")
                        } else {
                            Text("Latest")
                        }
                    }
                    
                    Button {
                        viewModel.selectedSort = .oldest
                    } label: {
                        if viewModel.selectedSort == .oldest {
                            Label("Oldest", systemImage: "checkmark")
                        } else {
                            Text("Oldest")
                        }
                    }
                }
                
                Section("Status") {
                    Button {
                        viewModel.selectedStatusFilter = (viewModel.selectedStatusFilter == .ongoing) ? .all : .ongoing
                    } label: {
                        if viewModel.selectedStatusFilter == .ongoing {
                            Label("Ongoing", systemImage: "checkmark")
                        } else {
                            Text("Ongoing")
                        }
                    }
                    
                    Button {
                        viewModel.selectedStatusFilter = (viewModel.selectedStatusFilter == .history) ? .all : .history
                    } label: {
                        if viewModel.selectedStatusFilter == .history {
                            Label("History", systemImage: "checkmark")
                        } else {
                            Text("History")
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 44, height: 44) // HIG hit target
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Sort and Filter Tasks")
        }
    }
    
    // MARK: - Task Card matching sample/Manager/Task log.svg
    @ViewBuilder
    private func taskCard(_ task: TaskLogItem) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            viewModel.selectTask(task)
        } label: {
            HStack(alignment: .center) {
                // Title and Timestamp
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
                
                // Status Badge & Chevron
                HStack(spacing: 8) {
                    StatusPillBadge(style: task.status == .ongoing ? .ongoing : .done)
                    
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
        .accessibilityLabel("\(task.title), \(task.formattedDateTime), Status: \(task.status.title)")
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
