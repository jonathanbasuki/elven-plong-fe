import SwiftUI

/// Reusable Task Instruction card: instruction text, location row, and a map area.
///
/// The map area defaults to `MapPlaceholderView`; pass a custom `map` view to replace it
/// (e.g. a real floor-plan snippet) without changing the card layout.
public struct TaskInstructionCard<MapContent: View>: View {
    public let instruction: String
    public let locationName: String
    public var mapHeight: CGFloat
    private let map: MapContent

    public init(
        instruction: String,
        locationName: String,
        mapHeight: CGFloat = 220,
        @ViewBuilder map: () -> MapContent
    ) {
        self.instruction = instruction
        self.locationName = locationName
        self.mapHeight = mapHeight
        self.map = map()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Instruction")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .accessibilityAddTraits(.isHeader)

                Text(instruction)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Location")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .accessibilityAddTraits(.isHeader)

                Label {
                    Text(locationName)
                        .font(.system(size: 14, weight: .medium))
                } icon: {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color(uiColor: .secondaryLabel))

                map
                    .frame(maxWidth: .infinity)
                    .frame(height: mapHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plongCardStyle()
    }
}

extension TaskInstructionCard where MapContent == MapPlaceholderView {
    /// Card with the default placeholder map area.
    public init(instruction: String, locationName: String, mapHeight: CGFloat = 220) {
        self.init(instruction: instruction, locationName: locationName, mapHeight: mapHeight) {
            MapPlaceholderView()
        }
    }

    /// Convenience initializer from a `TaskLogItem`.
    public init(task: TaskLogItem, mapHeight: CGFloat = 220) {
        self.init(instruction: task.instruction, locationName: task.locationName, mapHeight: mapHeight)
    }
}

/// Grey placeholder for the map area until a real map is wired in.
public struct MapPlaceholderView: View {
    public init() {}

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .systemGray6))

            Text("map")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
        .accessibilityLabel("Map placeholder")
    }
}

#Preview {
    ScrollView {
        TaskInstructionCard(
            task: TaskLogItem(
                title: "Overflow in Pantry",
                dateString: "3 October 2026",
                timeString: "14:05",
                status: .ongoing
            )
        )
        .padding(20)
    }
}
