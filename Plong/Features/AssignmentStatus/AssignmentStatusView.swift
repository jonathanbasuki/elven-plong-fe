import SwiftUI

public struct AssignmentStatusView: View {
    @Bindable var viewModel: AssignmentStatusViewModel
    
    public init(viewModel: AssignmentStatusViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Navigation
                HStack {
                    Button {
                        viewModel.navigateToZoneDetail()
                    } label: {
                        HStack(spacing: 4) {
                            Text("←")
                                .fontWeight(.bold)
                            Text("Zone Detail")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.navigateToMap()
                    } label: {
                        Text("Venue Map")
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 16)
                
                // Status Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("ASSIGNMENT STATUS REPORT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                    
                    Text("Deployment #\(viewModel.requestID.uuidString.prefix(8))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                if let request = viewModel.request {
                    // Status Badge & Details
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("STATUS:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            statusBadge(for: request.status)
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Metadata Table
                        VStack(alignment: .leading, spacing: 10) {
                            metadataRow(label: "Target Zone", value: viewModel.destinationZone?.name ?? "Unknown Zone")
                            metadataRow(label: "Task Type", value: request.taskType.rawValue)
                            metadataRow(label: "Dispatched", value: request.createdAt.formatted(date: .omitted, time: .standard))
                            metadataRow(label: "Window Expiration", value: request.expiresAt.formatted(date: .omitted, time: .standard))
                        }
                    }
                    .padding(16)
                    .background(Color(white: 0.96))
                    .border(Color.gray.opacity(0.3), width: 1)
                    .padding(.horizontal, 16)
                    
                    // Personnel Information (Revealed only if accepted)
                    if request.status == .accepted, let staff = viewModel.assignedStaff {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ASSIGNED PERSONNEL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(staff.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                    
                                    Text("Staff ID: \(staff.id.uuidString.prefix(8))")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Text("ACTIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black)
                            }
                            
                            if let assignment = viewModel.confirmedAssignment {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Deployment Progress: \(assignment.progress.rawValue)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.black)
                                    
                                    if assignment.progress != .completed {
                                        Button {
                                            viewModel.advanceProgress()
                                        } label: {
                                            Text("Advance to: \(nextProgressLabel(current: assignment.progress))")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.black)
                                                .padding(8)
                                                .frame(maxWidth: .infinity)
                                                .background(Color(white: 0.90))
                                                .border(Color.gray.opacity(0.5), width: 1)
                                        }
                                    } else {
                                        Text("✓ Task Completed on Site")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(white: 0.98))
                        .border(Color.black, width: 1)
                        .padding(.horizontal, 16)
                    } else if request.status == .pending {
                        VStack(spacing: 8) {
                            Text("Pending Staff Confirmation")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            Text("Candidate identity is concealed until acceptance is received.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(white: 0.98))
                        .border(Color.gray.opacity(0.3), width: 1)
                        .padding(.horizontal, 16)
                    } else if request.status == .expired {
                        VStack(spacing: 6) {
                            Text("Acceptance Window Expired")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            Text("The selected candidate did not respond within the 10-second limit. The system automatically proceeded to the next candidate.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(white: 0.98))
                        .border(Color.gray.opacity(0.3), width: 1)
                        .padding(.horizontal, 16)
                    } else if request.status == .declined {
                        VStack(spacing: 6) {
                            Text("Candidate Declined Request")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                            Text("Candidate was unable to accept. The coordinator dispatched the request to the next available staff member.")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(white: 0.98))
                        .border(Color.gray.opacity(0.3), width: 1)
                        .padding(.horizontal, 16)
                    }
                    
                    // Bottom Navigation Buttons
                    HStack(spacing: 12) {
                        Button {
                            viewModel.navigateToZoneDetail()
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
                            viewModel.navigateToMap()
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
                    .padding(.horizontal, 16)
                } else {
                    Text("Assignment record not found.")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(16)
                }
                
                Spacer(minLength: 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func statusBadge(for status: RequestStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(status == .accepted ? Color.white : (status == .expired || status == .declined ? Color.red : Color.black))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status == .accepted ? Color.black : Color(white: 0.90))
            .border(status == .expired || status == .declined ? Color.red : Color.clear, width: 1)
    }
    
    @ViewBuilder
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
        }
    }
    
    private func nextProgressLabel(current: AssignmentProgressStatus) -> String {
        switch current {
        case .accepted:
            return "On The Way"
        case .onTheWay:
            return "On Site"
        case .onSite:
            return "Completed"
        case .completed:
            return "Completed"
        }
    }
}
