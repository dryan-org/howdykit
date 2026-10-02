import SwiftUI

/// The button area every screen shares, rendered once by
/// `OnboardingFlowView` below the pages. Its height never changes: both
/// slots always take their space, and `actions == nil` (a page whose actions
/// haven't arrived yet) hides the buttons rather than removing them, so the
/// main button and the Skip line sit at the same spot on every screen and
/// nothing above the footer moves between pages.
struct OnboardingFooter: View {
    let actions: OnboardingActions?

    @Environment(\.onboardingTheme) private var theme

    private var primary: OnboardingAction {
        actions?.primary ?? OnboardingAction(title: "", handler: {})
    }

    private var secondary: OnboardingAction? {
        actions?.secondary
    }

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
            .opacity(actions == nil ? 0 : 1)
            .disabled(actions == nil)
            // No insertion/removal animation when prominence flips between
            // pages: an outgoing and incoming button overlapping for a frame
            // makes the footer momentarily taller.
            .transition(.identity)

            // One stable button, hidden rather than swapped for a placeholder,
            // for the same reason: a `Button`/`Color.clear` swap inside an
            // animated page change briefly stacks both.
            Button(secondary?.title ?? "", action: secondary?.handler ?? {})
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(theme.accentColor.opacity(0.85))
                .opacity(secondary == nil ? 0 : 1)
                .disabled(secondary == nil)
                .accessibilityHidden(secondary == nil)
                .frame(height: 44)
        }
        // `.borderedProminent`/`.bordered` otherwise fall back to the
        // system accent color, not the theme.
        .tint(theme.accentColor)
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
