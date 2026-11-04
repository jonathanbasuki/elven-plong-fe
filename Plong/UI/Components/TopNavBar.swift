import SwiftUI

public enum TopNavLeadingAction {
    case none
    case back(() -> Void)
    case close(() -> Void)
}

/// Standardized Top Navigation Bar conforming to Apple HIG.
/// Provides a persistent centered title & optional subtitle, back/close actions,
/// and an avatar button with a native pull-down menu for Profile & Logout.
public struct TopNavBar: View {
    public var title: String? = nil
    public var subtitle: String? = nil
    public var titleSize: CGFloat = 22
    public var leadingAction: TopNavLeadingAction = .none
    public var onLogout: (() -> Void)? = nil
    public var onProfileTap: (() -> Void)? = nil
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        titleSize: CGFloat = 22,
        leadingAction: TopNavLeadingAction = .none,
        onLogout: (() -> Void)? = nil,
        onProfileTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleSize = titleSize
        self.leadingAction = leadingAction
        self.onLogout = onLogout
        self.onProfileTap = onProfileTap
    }
    
    public var body: some View {
        ZStack {
            // Centered Title and optional Subtitle
            if let title = title {
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundStyle(Color(uiColor: .label))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .multilineTextAlignment(.center)
            }
            
            // Leading and Trailing Bar Actions
            HStack {
                leadingButton
                
                Spacer()
                
                trailingProfileItem
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
    
    // MARK: - Leading Button
    @ViewBuilder
    private var leadingButton: some View {
        switch leadingAction {
        case .none:
            Color.clear.frame(width: 44, height: 44)
            
        case .back(let action):
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 38, height: 38)
                    .background(Color(uiColor: .secondarySystemFill))
                    .clipShape(Circle())
                    .frame(width: 44, height: 44) // HIG hit target
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            
        case .close(let action):
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                    .frame(width: 38, height: 38)
                    .background(Color(uiColor: .secondarySystemFill))
                    .clipShape(Circle())
                    .frame(width: 44, height: 44) // HIG hit target
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
        }
    }
    
    // MARK: - Trailing Profile Item with Native Pull-Down Menu
    @ViewBuilder
    private var trailingProfileItem: some View {
        if let onLogout = onLogout {
            // Native Pull-Down Menu matching sort/filter behavior and Apple HIG
            Menu {
                Section {
                    Label("Rendi Septrian", systemImage: "person.crop.circle")
                    Text("Venue Security Manager")
                }
                
                Section {
                    Button(role: .destructive) {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onLogout()
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } label: {
                avatarImage
            }
            .accessibilityLabel("Profile options, Rendi Septrian")
        } else if let onProfileTap = onProfileTap {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                onProfileTap()
            } label: {
                avatarImage
            }
            .accessibilityLabel("Profile options")
        } else {
            Color.clear.frame(width: 44, height: 44)
        }
    }
    
    private var avatarImage: some View {
        Image("user_profile")
            .resizable()
            .scaledToFill()
            .frame(width: 38, height: 38)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
            )
            .frame(width: 44, height: 44) // HIG min hit target
            .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 20) {
        TopNavBar(title: "Overview", onLogout: {})
        TopNavBar(
            title: "Task Details",
            subtitle: "Overflow in Pantry",
            titleSize: 18,
            leadingAction: .back({})
        )
    }
}
