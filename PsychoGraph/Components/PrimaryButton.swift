import SwiftUI

// MARK: - Primary button (Figma spec)
// VStack(alignment: .center, spacing: 0) + padding(16) + frame(width: 280) + background + cornerRadius(66) + shadow
// Use this component for all primary CTAs; refer here for future changes.

/// Reusable primary CTA button. Design: teal background, cornerRadius 66, shadow.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    /// When true, button fills available width; when false, uses design width 280.
    var fullWidth: Bool = false

    private static let primaryTeal = Color(red: 0, green: 0.62, blue: 0.71)
    private static let cornerRadius: CGFloat = 66
    private static let padding: CGFloat = 16
    private static let designWidth: CGFloat = 280
    private static let shadowColor = Color.black.opacity(0.14)
    private static let shadowRadius: CGFloat = 14
    private static let shadowY: CGFloat = 8

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(Self.padding)
            .frame(width: fullWidth ? nil : Self.designWidth, alignment: .center)
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .buttonStyle(.plain)
        .background(Self.primaryTeal)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .shadow(color: Self.shadowColor, radius: Self.shadowRadius, x: 0, y: Self.shadowY)
    }
}

#Preview("Primary (280pt)") {
    PrimaryButton(title: "Next", action: {})
        .padding()
}

#Preview("Primary (full width)") {
    PrimaryButton(title: "Add Today's Graph", action: {}, fullWidth: true)
        .padding()
}
