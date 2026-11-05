import SwiftUI

/// Reusable task summary card: title, timestamp, and status pill.
///
/// - Pass `onTap` to make the card tappable; a trailing chevron is shown to indicate it opens details.
/// - Omit `onTap` for a static header (e.g. the top of a Task Detail screen) — no chevron is shown.
public struct TaskCard: View {
    public let title: String
    public let timestamp: String
    public let statusStyle: StatusBadgeStyle
    public var onTap: (() -> Void)?

    public init(
        title: String,
        timestamp: String,
        statusStyle: StatusBadgeStyle,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.timestamp = timestamp
        self.statusStyle = statusStyle
        self.onTap = onTap
    }

    /// Initializer for backend data that carries a real `Date` (formatted as "14:05, 3 October 2026").
    public init(
        title: String,
        date: Date,
        statusStyle: StatusBadgeStyle,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            timestamp: TaskCard.timestampFormatter.string(from: date),
            statusStyle: statusStyle,
            onTap: onTap
        )
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, d MMMM yyyy"
        return formatter
    }()

    /// Convenience initializer from a `TaskLogItem`.
    /// `ongoingStyle` lets each app label ongoing tasks differently (staff: `.accepted`, manager: `.ongoing`).
    public init(
        task: TaskLogItem,
        ongoingStyle: StatusBadgeStyle = .accepted,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            title: task.title,
            timestamp: task.formattedDateTime,
            statusStyle: task.status == .ongoing ? ongoingStyle : .done,
            onTap: onTap
        )
    }

    public var body: some View {
        if let onTap {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap()
            } label: {
                content(showsChevron: true)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens task details")
        } else {
            content(showsChevron: false)
                .accessibilityElement(children: .combine)
        }
    }

    private func content(showsChevron: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.leading)

                Text(timestamp)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                StatusPillBadge(style: statusStyle)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plongCardStyle()
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Shared card chrome

extension View {
    /// White rounded card with a subtle hairline border, shared by Plong task cards.
    func plongCardStyle(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 14) {
        TaskCard(
            task: TaskLogItem(title: "Overflow in Pantry", dateString: "3 October 2026", timeString: "14:05", status: .ongoing),
            onTap: {}
        )
        TaskCard(
            task: TaskLogItem(title: "Overflow in Lab 2", dateString: "1 October 2026", timeString: "13:12", status: .done),
            onTap: {}
        )
        TaskCard(
            task: TaskLogItem(title: "Overflow in Pantry", dateString: "3 October 2026", timeString: "14:05", status: .ongoing)
        )
    }
    .padding(20)
}
