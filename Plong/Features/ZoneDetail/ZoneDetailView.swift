import SwiftUI

public struct ZoneDetailView: View {
    @Bindable var viewModel: ZoneDetailViewModel
    
    public init(viewModel: ZoneDetailViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Navigation Header
                HStack {
                    Button {
                        viewModel.navigateBack()
                    } label: {
                        HStack(spacing: 4) {
                            Text("←")
                                .fontWeight(.bold)
                            Text("Venue Map")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                if let zone = viewModel.zone {
                    // Zone Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ZONE DETAILS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                
                                Text(zone.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                            }
                            
                            Spacer()
                            
                            Text(zone.crowdSeverity.label.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(zone.crowdSeverity == .high || zone.crowdSeverity == .critical ? Color.white : Color.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(zone.crowdSeverity == .high || zone.crowdSeverity == .critical ? Color.black : Color(white: 0.85))
                        }
                        
                        Divider()
                        
                        // Occupancy & Severity Metrics
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Crowd")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Text("\(zone.crowdCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                Text("occupants")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Security Needed")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Text("\(zone.requiredAdditionalSecurity)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(zone.requiredAdditionalSecurity > 0 ? .black : .gray)
                                Text("additional personnel")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(Color(white: 0.96))
                    .border(Color.gray.opacity(0.3), width: 1)
                    .padding(.horizontal, 16)
                    
                    // Confirmed Security Assignments Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("CONFIRMED SECURITY PERSONNEL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            Spacer()
                            
                            Text("\(viewModel.assignedStaff.count) Assigned")
                                .font(.caption)
                                .foregroundStyle(.black)
                        }
                        
                        Divider()
                        
                        if viewModel.assignedStaff.isEmpty {
                            // Empty state
                            VStack(spacing: 8) {
                                Text("No Security Personnel Deployed")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                
                                Text("This zone currently operates without dedicated security manpower. Initiate a broadcast below to request deployment.")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .border(Color.gray.opacity(0.2), width: 1)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.assignedStaff) { staff in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(staff.name)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.black)
                                            
                                            Text("Active on site • Status: \(staff.availabilityStatus.rawValue)")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("CONFIRMED")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(white: 0.90))
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .border(Color.gray.opacity(0.2), width: 1)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(white: 0.98))
                    .border(Color.gray.opacity(0.3), width: 1)
                    .padding(.horizontal, 16)
                    
                    // Broadcast Action Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MANPOWER DISPATCH")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        Text("System automatically dispatches request to the nearest available candidate based on indoor proximity. Selection is automated.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        
                        Button {
                            viewModel.initiateBroadcast()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Broadcast Security Request")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.black)
                        }
                    }
                    .padding(16)
                    .background(Color(white: 0.96))
                    .border(Color.black, width: 1)
                    .padding(.horizontal, 16)
                    
                } else {
                    Text("Zone not found.")
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
}
