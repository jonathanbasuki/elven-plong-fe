import SwiftUI

public struct AlertsView: View {
    @Bindable var viewModel: AlertsViewModel
    
    public init(viewModel: AlertsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.alerts.isEmpty {
                    ContentUnavailableView(
                        "No Alerts Recorded",
                        systemImage: "bell.slash",
                        description: Text("System notifications will appear here when crowd thresholds or deployment events occur.")
                    )
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.alerts) { alert in
                            Button {
                                viewModel.selectAlert(alert)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 10) {
                                        // Unread Indicator or Icon
                                        ZStack {
                                            Circle()
                                                .fill(alertIconBackground(for: alert.alertType))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: alertIcon(for: alert.alertType))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(alertIconColor(for: alert.alertType))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(alert.title)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(.primary)
                                                
                                                if !alert.isRead {
                                                    Circle()
                                                        .fill(Color.accentColor)
                                                        .frame(width: 6, height: 6)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(alert.createdAt.formatted(date: .omitted, time: .shortened))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Text(viewModel.getZoneName(for: alert.zoneID))
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Text(alert.message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.leading, 42)
                                    
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text("Inspect Zone")
                                                .font(.caption2.weight(.semibold))
                                            Image(systemName: "chevron.right")
                                                .font(.caption2.weight(.semibold))
                                        }
                                        .foregroundStyle(.primary)
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(14)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.primary.opacity(alert.isRead ? 0.05 : 0.12), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Alerts & Logs")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func alertIcon(for type: AlertType) -> String {
        switch type {
        case .highCrowdDetected:
            return "exclamationmark.triangle.fill"
        case .crowdDensityIncreasing:
            return "chart.line.uptrend.xyaxis"
        case .securityBroadcastSent:
            return "antenna.radiowaves.left.and.right"
        case .assignmentAccepted:
            return "checkmark.shield.fill"
        case .assignmentRequestExpired:
            return "clock.arrow.circlepath"
        case .noAvailableSecurity:
            return "xmark.octagon.fill"
        }
    }
    
    private func alertIconColor(for type: AlertType) -> Color {
        switch type {
        case .highCrowdDetected, .noAvailableSecurity:
            return .red
        case .crowdDensityIncreasing:
            return .orange
        case .securityBroadcastSent:
            return .primary
        case .assignmentAccepted:
            return .green
        case .assignmentRequestExpired:
            return .secondary
        }
    }
    
    private func alertIconBackground(for type: AlertType) -> Color {
        switch type {
        case .highCrowdDetected, .noAvailableSecurity:
            return Color.red.opacity(0.12)
        case .crowdDensityIncreasing:
            return Color.orange.opacity(0.12)
        case .securityBroadcastSent:
            return Color.primary.opacity(0.06)
        case .assignmentAccepted:
            return Color.green.opacity(0.12)
        case .assignmentRequestExpired:
            return Color.secondary.opacity(0.1)
        }
    }
}
