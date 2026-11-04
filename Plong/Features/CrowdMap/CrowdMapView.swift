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
                    
                    // Summary Metric Cards
                    summaryMetricCards
                    
                    // Interactive Zoomable Floor Plan
                    InteractiveFloorPlanView(
                        pantryZone: viewModel.pantryZone,
                        collabZone: viewModel.collabZone,
                        meetingZone: viewModel.meetingZone,
                        onSelectZone: { zone in
                            viewModel.selectZoneForDetail(zone: zone)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, showChrome ? 96 : 80) // Clearance for floating tab bar
                }
                .padding(.top, showChrome ? 0 : 8)
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
