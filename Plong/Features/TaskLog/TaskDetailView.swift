import SwiftUI
import Charts

public struct CrowdDataPoint: Identifiable {
    public let id = UUID()
    public let time: String
    public let count: Int
    
    public init(time: String, count: Int) {
        self.time = time
        self.count = count
    }
}

/// Task Detail View matching sample/Manager/TaskDetail.svg (Ongoing)
/// and sample/Manager/TaskDetailDone.svg (Done).
/// Fully conforming to Apple HIG.
public struct TaskDetailView: View {
    public let task: TaskLogItem
    public let router: NavigationRouter
    
    // Sample crowd trend points matching TaskDetailDone.svg
    private let crowdTrendData: [CrowdDataPoint] = [
        CrowdDataPoint(time: "0", count: 50),
        CrowdDataPoint(time: "13.15", count: 48),
        CrowdDataPoint(time: "13.30", count: 49),
        CrowdDataPoint(time: "13.45", count: 42),
        CrowdDataPoint(time: "14.00", count: 44)
    ]
    
    public init(task: TaskLogItem, router: NavigationRouter) {
        self.task = task
        self.router = router
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Nav Bar with back action and centered title/subtitle
            TopNavBar(
                title: "Task Details",
                subtitle: task.title,
                titleSize: 18,
                leadingAction: .back {
                    router.pop()
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Task Card
                    taskHeaderCard
                    
                    if task.status == .ongoing {
                        ongoingContent
                    } else {
                        doneContent
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Task Card
    private var taskHeaderCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(task.formattedDateTime)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            StatusPillBadge(style: task.status == .ongoing ? .ongoing : .done)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Ongoing Layout (sample/Manager/TaskDetail.svg)
    @ViewBuilder
    private var ongoingContent: some View {
        // Status and Crowd Count Row
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Status")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text("Overflow")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(red: 0.85, green: 0.20, blue: 0.20))
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 4) {
                Text("Crowd Count")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text("50")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
        
        // CCTV Snapshot
        Image("cctv_snapshot")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        
        // Active Staff in Area Section
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Staff in Area")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            staffDetailRow(name: "Rendi Septrian", role: "Security", statusLine1: "Active Staff", statusLine2: "Pantry")
            Divider().opacity(0.4)
            staffDetailRow(name: "Rendi Septrian", role: "Security", statusLine1: "Active Staff", statusLine2: "Pantry")
            Divider().opacity(0.4)
            staffDetailRow(name: "Rendi Septrian", role: "Security", statusLine1: "Enroute", statusLine2: "Lab 1")
            Divider().opacity(0.4)
            staffDetailRow(name: "Rendi Septrian", role: "Security", statusLine1: "Enroute", statusLine2: "Terrace")
            Divider().opacity(0.4)
            staffDetailRow(name: "Rendi Septrian", role: "Security", statusLine1: "Enroute", statusLine2: "Terrace")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Done Layout (sample/Manager/TaskDetailDone.svg)
    @ViewBuilder
    private var doneContent: some View {
        // Total Crowd Trend Section
        VStack(alignment: .leading, spacing: 10) {
            Text("Total Crowd Trend")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            
            // Swift Charts Line Chart
            Chart {
                ForEach(crowdTrendData) { item in
                    LineMark(
                        x: .value("Time", item.time),
                        y: .value("Crowd", item.count)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color(red: 0.05, green: 0.49, blue: 0.95))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Time", item.time),
                        y: .value("Crowd", item.count)
                    )
                    .symbol {
                        Circle()
                            .fill(Color(uiColor: .systemBackground))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.05, green: 0.49, blue: 0.95), lineWidth: 2.5)
                            )
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                        .font(.system(size: 11))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel()
                        .font(.system(size: 11))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            .frame(height: 160)
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        
        // Active Staff in Area Section
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Staff in Area")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            staffSimpleRow(name: "Rendi Septrian", role: "Security", statusText: "Onsite")
            Divider().opacity(0.4)
            staffSimpleRow(name: "Rendi Septrian", role: "Security", statusText: "Onsite")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // Assigned Staff Section
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Staff")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            staffSimpleRow(name: "Rendi Septrian", role: "Security", statusText: "Lab 1")
            Divider().opacity(0.4)
            staffSimpleRow(name: "Rendi Septrian", role: "Security", statusText: "Lab 2")
            Divider().opacity(0.4)
            staffSimpleRow(name: "Rendi Septrian", role: "Security", statusText: "Terrace")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // CCTV Report Section
        VStack(alignment: .leading, spacing: 10) {
            Text("CCTV Report")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            VStack(spacing: 8) {
                Image("cctv_snapshot")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                
                Text(task.formattedDateTime)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Row Helpers
    private func staffDetailRow(name: String, role: String, statusLine1: String, statusLine2: String) -> some View {
        HStack(spacing: 14) {
            Image("user_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(role)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(statusLine1)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                
                Text(statusLine2)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
    }
    
    private func staffSimpleRow(name: String, role: String, statusText: String) -> some View {
        HStack(spacing: 14) {
            Image("user_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(role)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer()
            
            Text(statusText)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }
}

#Preview {
    TaskDetailView(
        task: TaskLogItem(
            title: "Overflow in Pantry",
            dateString: "3 October 2026",
            timeString: "14:05",
            status: .ongoing
        ),
        router: NavigationRouter()
    )
}

