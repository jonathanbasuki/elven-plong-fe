import SwiftUI

public struct AlertsView: View {
    @Bindable var viewModel: AlertsViewModel
    
    public init(viewModel: AlertsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Button {
                        viewModel.navigateBack()
                    } label: {
                        HStack(spacing: 4) {
                            Text("←")
                                .fontWeight(.bold)
                            Text("Back")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SYSTEM NOTIFICATIONS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    
                    Text("Venue Alerts & Logs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                if viewModel.alerts.isEmpty {
                    VStack(spacing: 8) {
                        Text("No Alerts Recorded")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                        
                        Text("System notifications will appear here when crowd thresholds or deployment events occur.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(white: 0.98))
                    .border(Color.gray.opacity(0.3), width: 1)
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.alerts) { alert in
                            Button {
                                viewModel.selectAlert(alert)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        if !alert.isRead {
                                            Rectangle()
                                                .fill(Color.black)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 4)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(alert.title)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.black)
                                            
                                            Text(viewModel.getZoneName(for: alert.zoneID))
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(alert.createdAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Text(alert.message)
                                        .font(.caption)
                                        .foregroundStyle(.black)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack {
                                        Text(alertBadgeText(for: alert.alertType))
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(white: 0.90))
                                        
                                        Spacer()
                                        
                                        Text("Tap to view details →")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding(12)
                                .background(alert.isRead ? Color(white: 0.98) : Color.white)
                                .border(alert.isRead ? Color.gray.opacity(0.3) : Color.black, width: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer(minLength: 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    private func alertBadgeText(for type: AlertType) -> String {
        switch type {
        case .highCrowdDetected:
            return "CROWD CRITICAL"
        case .crowdDensityIncreasing:
            return "DENSITY SURGE"
        case .securityBroadcastSent:
            return "BROADCAST SENT"
        case .assignmentAccepted:
            return "DEPLOYMENT CONFIRMED"
        case .assignmentRequestExpired:
            return "REQUEST TIMEOUT"
        case .noAvailableSecurity:
            return "DISPATCH FAILED"
        }
    }
}
