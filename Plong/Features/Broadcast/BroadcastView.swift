import SwiftUI

public struct BroadcastView: View {
    @Bindable var viewModel: BroadcastViewModel
    
    public init(viewModel: BroadcastViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BROADCAST DISPATCH")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        Text("Automated Security Request")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                    }
                    
                    Spacer()
                    
                    if case .waitingForResponse = viewModel.sessionStatus {
                        Button {
                            viewModel.cancelBroadcast()
                        } label: {
                            Text("Cancel")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .border(Color.red, width: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Target Zone & Task Details Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TARGET DESTINATION")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text(viewModel.zone?.name ?? "Unknown Zone")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TASK TYPE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Text(viewModel.taskType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.black)
                        }
                    }
                }
                .padding(14)
                .background(Color(white: 0.96))
                .border(Color.gray.opacity(0.3), width: 1)
                .padding(.horizontal, 16)
                
                // Primary Status Area
                mainStatusCard
                    .padding(.horizontal, 16)
                
                // DEBUG TEST CONTROLS (Required for low-fidelity MVP verification)
                debugTestingSection
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    // MARK: - Main Status Card
    
    @ViewBuilder
    private var mainStatusCard: some View {
        switch viewModel.sessionStatus {
        case .idle, .selectingCandidate:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.black)
                Text("Analyzing Proximity & Selecting Nearest Candidate...")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(white: 0.98))
            .border(Color.gray.opacity(0.3), width: 1)
            
        case .waitingForResponse:
            VStack(alignment: .center, spacing: 16) {
                // Countdown Clock (Low-fidelity visual)
                VStack(spacing: 6) {
                    Text("ACCEPTANCE WINDOW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    
                    Text("\(viewModel.remainingSeconds)s")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(viewModel.remainingSeconds <= 3 ? Color.red : Color.black)
                    
                    // Simple linear countdown bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(white: 0.90))
                                .frame(height: 8)
                            
                            Rectangle()
                                .fill(viewModel.remainingSeconds <= 3 ? Color.red : Color.black)
                                .frame(width: max(0, geo.size.width * CGFloat(viewModel.remainingSeconds) / 10.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                
                Divider()
                
                VStack(spacing: 6) {
                    Text("Candidate Dispatched")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                    
                    Text("Nearest available security staff member was selected automatically.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("(Identity protected until assignment confirmed)")
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.gray)
                }
                
                if viewModel.attemptedCandidatesCount > 0 {
                    HStack(spacing: 4) {
                        Text("Sequential candidate attempt #\(viewModel.attemptedCandidatesCount + 1)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.94))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.98))
            .border(Color.black, width: 1)
            
        case .accepted(let assignmentID, let staffName):
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("✓ ASSIGNMENT CONFIRMED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned Security Officer:")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Text(staffName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                
                Text("The candidate accepted within the 10-second window. The deployment has been confirmed and the zone occupancy status is updated.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Divider()
                
                HStack(spacing: 12) {
                    if let request = viewModel.currentRequest {
                        Button {
                            viewModel.viewAssignmentStatus(requestID: request.id)
                        } label: {
                            Text("View Assignment Status")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                        }
                    }
                    
                    Button {
                        viewModel.backToMap()
                    } label: {
                        Text("Venue Map")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.92))
                            .border(Color.gray.opacity(0.4), width: 1)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.96))
            .border(Color.black, width: 2)
            
        case .failedNoCandidates(let reason):
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("✕ DEPLOYMENT FAILED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                    
                    Spacer()
                }
                
                Text("No Available Security Candidates")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Divider()
                
                HStack(spacing: 12) {
                    Button {
                        viewModel.backToZone()
                    } label: {
                        Text("Return to Zone")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                    }
                    
                    Button {
                        viewModel.backToMap()
                    } label: {
                        Text("Venue Map")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.92))
                            .border(Color.gray.opacity(0.4), width: 1)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.98))
            .border(Color.red, width: 1)
            
        case .cancelled:
            VStack(alignment: .leading, spacing: 12) {
                Text("BROADCAST CANCELLED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                
                Text("The broadcast request was cancelled by the venue manager.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                Button {
                    viewModel.backToZone()
                } label: {
                    Text("Return to Zone")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(10)
                        .background(Color(white: 0.92))
                        .border(Color.gray.opacity(0.4), width: 1)
                }
            }
            .padding(16)
            .background(Color(white: 0.98))
            .border(Color.gray.opacity(0.3), width: 1)
        }
    }
    
    // MARK: - Debug Testing Section
    
    @ViewBuilder
    private var debugTestingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("[DEBUG / MOCK TEST CONTROLS]")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                Spacer()
                Text("Simulates Staff Watch App")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            
            Text("Simulate staff candidate actions during the 10-second window:")
                .font(.caption2)
                .foregroundStyle(.gray)
            
            if case .waitingForResponse = viewModel.sessionStatus {
                HStack(spacing: 8) {
                    Button {
                        viewModel.debugSimulateAccept()
                    } label: {
                        Text("Simulate Accept")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                    }
                    
                    Button {
                        viewModel.debugSimulateDecline()
                    } label: {
                        Text("Simulate Decline")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.92))
                            .border(Color.gray.opacity(0.5), width: 1)
                    }
                    
                    Button {
                        viewModel.debugSimulateTimeout()
                    } label: {
                        Text("Force Timeout")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.92))
                            .border(Color.gray.opacity(0.5), width: 1)
                    }
                }
            } else {
                Text("Controls active when a candidate is awaiting response.")
                    .font(.caption2)
                    .italic()
                    .foregroundStyle(.gray)
            }
            
            Divider()
            
            Button {
                viewModel.debugToggleForceNoCandidates()
            } label: {
                HStack {
                    Text(viewModel.coordinator.debugForceNoCandidates ? "✓ Simulating Empty Staff Pool (Active)" : "Simulate 'No Available Staff' Pool")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.coordinator.debugForceNoCandidates ? Color.red : Color.black)
                    Spacer()
                }
                .padding(8)
                .background(Color(white: 0.95))
                .border(viewModel.coordinator.debugForceNoCandidates ? Color.red : Color.gray.opacity(0.4), width: 1)
            }
        }
        .padding(14)
        .background(Color(white: 0.95))
        .border(Color.gray.opacity(0.5), width: 1)
    }
}
