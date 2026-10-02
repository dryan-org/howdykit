import SwiftUI

/// The page dots under an `OnboardingFlowView`'s pager. Always takes the
/// same height and hides (rather than leaves) for a single page, so nothing
/// above or below it shifts.
struct OnboardingPageIndicator: View {
    let count: Int
    let current: Int

    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? theme.primaryColor : Color.secondary.opacity(0.35))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 20)
        .opacity(count > 1 ? 1 : 0)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}
