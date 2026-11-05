import SwiftUI

/// Crowd Map Overview View matching sample/Manager/overview1.svg and overview2.svg.
/// Conforms to Apple HIG for layout, modality, and interactive zooming/panning.
public struct CrowdMapView: View {
    @Bindable var viewModel: CrowdMapViewModel
    public var showChrome: Bool = false
    
    public init(viewModel: CrowdMapViewModel, showChrome: Bool = false) {
        self.viewModel = viewModel
        self.showChrome = showChrome
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if showChrome {
                        TopNavBar(title: "Overview", onLogout: {
                            viewModel.logout()
                        })
                        .padding(.top, 4)
                    }
                    
                    // Top Task Done Banner matching sample/Manager/overview done.svg
                    if viewModel.delegationStatus == .done {
                        taskDoneBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Summary Metric Cards
                    summaryMetricCards
                    
                    // Native Fluid Zoomable Floor Plan (120Hz ProMotion & UIScrollView inertia)
                    NativeZoomableFloorPlan(
                        pantryZone: viewModel.pantryZone,
                        collabZone: viewModel.collabZone,
                        meetingZone: viewModel.meetingZone,
                        delegationStatus: viewModel.delegationStatus,
                        onSelectZone: { zone in
                            viewModel.selectZoneForDetail(zone: zone)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, showChrome ? 96 : 80) // Clearance for floating tab bar
                }
                .padding(.top, showChrome ? 0 : 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.delegationStatus)
            }
            
            if showChrome {
                FloatingTabBar(activeTab: .overview) { tab in
                    if tab == .taskLog {
                        viewModel.openTaskLog()
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
        .sheet(item: $viewModel.selectedZoneForDetail) { zone in
            ZoneDetailModalView(
                zone: zone,
                isOngoingDelegation: viewModel.delegationStatus == .ongoing,
                availableStaffCount: viewModel.availableStaffCount,
                onDismiss: {
                    viewModel.selectedZoneForDetail = nil
                },
                onConfirmDelegation: { targetZone, staffNeeded, instruction in
                    viewModel.confirmDelegation(zone: targetZone, staffNeeded: staffNeeded, instruction: instruction)
                }
            )
            .presentationDetents([.fraction(0.85), .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Task Done Push Banner matching overview done.svg
    private var taskDoneBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 38, height: 38)
                
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Plong")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Task done ✅")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            Spacer()
            
            Text("Now")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
    }
    
    // MARK: - Summary Metric Cards
    private var summaryMetricCards: some View {
        HStack(spacing: 12) {
            // Active Staff Card
            VStack(spacing: 4) {
                Text("Active Staff")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text("\(viewModel.activeStaffCount)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 19.5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19.5, style: .continuous)
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            )
            
            // Total Crowd Card
            VStack(spacing: 4) {
                Text("Total Crowd")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text("\(viewModel.totalCrowd)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 19.5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19.5, style: .continuous)
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    CrowdMapView(
        viewModel: CrowdMapViewModel(
            repository: MockCrowdFlowRepository(),
            router: NavigationRouter()
        ),
        showChrome: true
    )
}
