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
        CrowdDataPoint(time: "13.15", count: 24),
        CrowdDataPoint(time: "13.20", count: 52),
        CrowdDataPoint(time: "13.25", count: 27),
        CrowdDataPoint(time: "13.30", count: 55),
        CrowdDataPoint(time: "13.35", count: 77),
        CrowdDataPoint(time: "13.40", count: 70),
        CrowdDataPoint(time: "13.45", count: 26)
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
        TaskCard(
            title: task.title,
            timestamp: task.formattedDateTime,
            statusStyle: task.status == .ongoing ? .ongoing : .done
        )
    }
    
    // MARK: - Ongoing Layout (sample/Manager/TaskDetail Enroute.svg)
    @ViewBuilder
    private var ongoingContent: some View {
        // Status and Crowd Count Row
        StatusMetricsRow(crowdCount: 50)
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
        
        // Task Instruction Section
        VStack(alignment: .leading, spacing: 6) {
            Text("Task Instruction :")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))
            
            Text(task.instruction)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // Assigned Staff Section matching TaskDetail Enroute.svg
        VStack(alignment: .leading, spacing: 14) {
            Text("Assigned Staff")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Active Staff")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Active Staff")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Enroute")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Enroute")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Enroute")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Enroute")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Done Layout (sample/Manager/TaskDetailDone.svg)
    @ViewBuilder
    private var doneContent: some View {
        // Total Crowd Trend Section with Bar Chart matching TaskDetailDone.svg
        VStack(alignment: .leading, spacing: 10) {
            Text("Total Crowd Trend")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            
            Chart {
                ForEach(crowdTrendData) { item in
                    BarMark(
                        x: .value("Time", item.time),
                        y: .value("Crowd", item.count),
                        width: .fixed(18)
                    )
                    .foregroundStyle(Color(red: 0.05, green: 0.49, blue: 0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .annotation(position: .top, spacing: 4) {
                        Text("\(item.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
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
                        .font(.system(size: 10))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
        
        // CCTV Report Section
        VStack(alignment: .leading, spacing: 8) {
            Text("CCTV Report")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            Text("13:12, 1 October 2026")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            
            Image("cctv_snapshot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // Task Instruction Section
        VStack(alignment: .leading, spacing: 6) {
            Text("Task Instruction :")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))
            
            Text(task.instruction)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // Assigned Staff Section
        VStack(alignment: .leading, spacing: 14) {
            Text("Assigned Staff")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.top, 4)
            
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "")
            Divider().opacity(0.4)
            StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

