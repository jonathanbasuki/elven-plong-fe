import SwiftUI
import Observation

@Observable
@MainActor
public final class CreateBroadcastViewModel {
    public let zoneID: String
    public let repository: CrowdFlowRepositoryProtocol
    public let coordinator: AssignmentCoordinator
    public let router: NavigationRouter
    
    public var staffNeeded: Int = 3
    public var errorMessage: String? = nil
    public var isSubmitting: Bool = false
    
    public init(
        zoneID: String,
        repository: CrowdFlowRepositoryProtocol,
        coordinator: AssignmentCoordinator,
        router: NavigationRouter
    ) {
        self.zoneID = zoneID
        self.repository = repository
        self.coordinator = coordinator
        self.router = router
    }
    
    public var zone: VenueZone? {
        repository.getZone(by: zoneID)
    }
    
    public func confirmBroadcast() {
        errorMessage = nil
        isSubmitting = true
        
        do {
            try coordinator.startBroadcast(zoneID: zoneID, staffNeeded: staffNeeded)
            isSubmitting = false
            router.navigate(to: .broadcast(zoneID: zoneID))
        } catch let error as BroadcastError {
            isSubmitting = false
            errorMessage = error.localizedDescription
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}

public struct CreateBroadcastView: View {
    @Bindable var viewModel: CreateBroadcastViewModel
    
    public init(viewModel: CreateBroadcastViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Target Zone Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.zone?.name ?? "Zone \(viewModel.zoneID)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            if let zone = viewModel.zone {
                                Text("\(zone.currentCount) occupants · \(zone.status.label.capitalized)")
                                    .font(.footnote)
                                    .foregroundStyle(zoneStatusColor(zone.status))
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 4)
                
                // Staff Needed Selector Card
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Officers Needed")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Select how many officers to dispatch to this zone.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    // 1 to 5 Pill Selection
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { count in
                            Button {
                                viewModel.staffNeeded = count
                            } label: {
                                Text("\(count)")
                                    .font(.headline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .foregroundStyle(viewModel.staffNeeded == count ? Color(uiColor: .systemBackground) : Color.primary)
                                    .background(viewModel.staffNeeded == count ? Color.primary : Color(uiColor: .tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Text("Dispatches to all available officers simultaneously with a 20-second acceptance window.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                
                // Error Alert if any
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                        .padding(.horizontal, 16)
                }
                
                // Confirm Action Button
                confirmButton
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("New Broadcast")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    @ViewBuilder
    private var confirmButton: some View {
        Button {
            viewModel.confirmBroadcast()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(Color(uiColor: .systemBackground))
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Confirm Broadcast")
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(Color(uiColor: .systemBackground))
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(viewModel.isSubmitting)
    }
    
    private func zoneStatusColor(_ status: ZoneStatus) -> Color {
        switch status {
        case .safe: return .secondary
        case .warning: return .orange
        case .crowded: return .red
        }
    }
}
