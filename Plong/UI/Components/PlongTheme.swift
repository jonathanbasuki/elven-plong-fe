import SwiftUI

/// Unified Design System and Theme Tokens for Plong (Light Mode).
/// Standardizes color palette, shadows, corner radii, and spacing across the application.
public enum PlongTheme {
    
    // MARK: - Color Palette
    public enum Colors {
        /// Primary brand accent blue (#006ADA) used for primary action CTA buttons
        public static let brandBlue = Color(red: 0/255, green: 106/255, blue: 218/255)
        
        /// iOS standard blue (#007AFF) used for ongoing task tags and active tab indicators
        public static let ongoingBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
        
        /// Subtle cyan-blue background (#EAF6F9) for ongoing task pills
        public static let ongoingBackground = Color(red: 234/255, green: 246/255, blue: 249/255)
        
        /// Forest/emerald green (#27AE60) for completed tasks
        public static let doneGreen = Color(red: 39/255, green: 174/255, blue: 96/255)
        
        /// Soft mint green background (#EAF8EC) for completed task pills
        public static let doneBackground = Color(red: 234/255, green: 248/255, blue: 236/255)
        
        /// Critical alert red (#FF383C) for overflow indicators and crowded pins
        public static let overflowRed = Color(red: 255/255, green: 56/255, blue: 60/255)
        
        /// Neutral soft gray (#D9D9D9) for unassigned / candidate staff card slots
        public static let slotCardBackground = Color(red: 217/255, green: 217/255, blue: 217/255)
        
        /// Secondary button fill (#767680 @ 12% opacity)
        public static let secondaryButtonBackground = Color(red: 118/255, green: 118/255, blue: 128/255).opacity(0.12)
        
        /// Inactive / disabled text fill (#3C3C43 @ 30% opacity)
        public static let disabledText = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.3)
        
        /// Subdued officer & label text (#727272)
        public static let officerText = Color(red: 114/255, green: 114/255, blue: 114/255)
        
        /// Tertiary icon & metadata gray (#8E8E93)
        public static let metadataText = Color(red: 142/255, green: 142/255, blue: 147/255)
        
        /// Clean light background
        public static let pageBackground = Color(uiColor: .systemBackground)
        
        /// Secondary grouped background for cards
        public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        
        /// Clean white
        public static let pureWhite = Color.white
    }
    
    // MARK: - Radius Tokens
    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 14
        public static let card: CGFloat = 20
        public static let pill: CGFloat = 25
    }
    
    // MARK: - Spacing Tokens
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }
}
