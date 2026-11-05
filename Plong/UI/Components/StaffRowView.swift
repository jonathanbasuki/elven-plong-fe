import SwiftUI

/// Reusable staff row displaying staff avatar, name, role, and current status.
/// Conforms to Apple HIG: clear hierarchy, accessible touch targets, and consistent alignment.
public struct StaffRowView: View {
    public let name: String
    public let role: String
    public var statusText: String
    public var statusSubtitle: String?
    public var avatarImage: String
    
    public init(
        name: String,
        role: String = "Security",
        statusText: String = "",
        statusSubtitle: String? = nil,
        avatarImage: String = "user_profile"
    ) {
        self.name = name
        self.role = role
        self.statusText = statusText
        self.statusSubtitle = statusSubtitle
        self.avatarImage = avatarImage
    }
    
    /// Convenience initializer from domain `SecurityStaff` model for backend integration.
    public init(
        staff: SecurityStaff,
        role: String = "Security",
        statusText: String? = nil,
        avatarImage: String = "user_profile"
    ) {
        self.name = staff.name
        self.role = role
        self.statusText = statusText ?? staff.status.label
        self.statusSubtitle = nil
        self.avatarImage = avatarImage
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Staff Avatar with circle crop and subtle hairline border
            Image(avatarImage)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            
            // Name and Role
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                
                Text(role)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            
            Spacer(minLength: 8)
            
            // Trailing Status (Single line or two-line status)
            if let statusSubtitle = statusSubtitle, !statusSubtitle.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(statusText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    
                    Text(statusSubtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            } else if !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(role), \(statusText)")
    }
}

#Preview {
    VStack(spacing: 12) {
        StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Active Staff")
        Divider()
        StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Enroute")
        Divider()
        StaffRowView(name: "Rendi Septrian", role: "Security", statusText: "Onsite • Pantry")
    }
    .padding(20)
}
