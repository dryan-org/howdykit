import SwiftUI

/// The button area every screen shares, rendered once by
/// `OnboardingFlowView` below the pages. Both slots always take their space,
/// visible or not, so the main button and the Skip line sit at the same spot
/// on the welcome, on a step with Skip, and on one without; nothing jumps
/// between pages.
struct OnboardingFooter: View {
    let primary: OnboardingAction
    let secondary: OnboardingAction?

    @Environment(\.onboardingTheme) private var theme

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if primary.isProminent {
                    primaryButton.buttonStyle(.borderedProminent)
                } else {
                    primaryButton.buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
            // No insertion/removal animation when prominence flips between
            // pages: an outgoing and incoming button overlapping for a frame
            // makes the footer momentarily taller and everything above it
            // (content, page dots) visibly settles.
            .transition(.identity)

            // One stable button, hidden rather than swapped for a placeholder,
            // for the same reason: a `Button`/`Color.clear` swap inside an
            // animated page change briefly stacks both.
            Button(secondary?.title ?? "", action: secondary?.handler ?? {})
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(theme.primaryColor.opacity(0.85))
                .opacity(secondary == nil ? 0 : 1)
                .disabled(secondary == nil)
                .accessibilityHidden(secondary == nil)
                .frame(height: 44)
        }
        // `.borderedProminent`/`.bordered` otherwise fall back to the
        // system accent color, not the theme.
        .tint(theme.primaryColor)
        .padding(.horizontal, 28)
        .padding(.top, 8)
        // The page control no longer overlaps this: the footer sits below
        // the TabView, so the dots are above it.
        .padding(.bottom, 12)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var primaryButton: some View {
        Button(action: primary.handler) {
            Text(primary.title)
                .frame(maxWidth: .infinity)
        }
    }
}
