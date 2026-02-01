import SwiftUI

/// Calm / Insight Timer–inspired design system: serene palette, generous spacing, card-style sections.
enum AppTheme {
    // MARK: - Colors (soft sage/teal, warm neutrals)
    static let primary = Color(red: 0.32, green: 0.52, blue: 0.52)       // Sage teal
    static let primaryLight = Color(red: 0.32, green: 0.52, blue: 0.52).opacity(0.15)
    static let surface = Color(red: 0.98, green: 0.98, blue: 0.97)       // Warm off-white
    static let cardBackground = Color(red: 1, green: 1, blue: 1)
    static let cardShadow = Color.black.opacity(0.04)
    static let textPrimary = Color.primary
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.47)
    static let textTertiary = Color(red: 0.58, green: 0.58, blue: 0.6)
    static let divider = Color(red: 0.9, green: 0.9, blue: 0.92)
    static let filledDot = Color(red: 0.32, green: 0.52, blue: 0.52)
    static let emptyDot = Color(red: 0.88, green: 0.88, blue: 0.9)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let sectionSpacing: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let cardCornerRadiusSmall: CGFloat = 12

    // MARK: - Typography
    static func sectionHeader() -> Font { .system(size: 13, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func bodyMedium() -> Font { .system(size: 16, weight: .medium) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func captionSecondary() -> Font { .system(size: 12, weight: .regular) }
    static func title() -> Font { .system(size: 22, weight: .semibold) }
    static func largeTitle() -> Font { .system(size: 28, weight: .bold) }
}
