import SwiftUI

/// The button area every screen shares. Both slots always take their space,
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

            Group {
                if let secondary {
                    Button(secondary.title, action: secondary.handler)
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryColor.opacity(0.85))
                } else {
                    Color.clear
                }
            }
            .frame(height: 44)
        }
        // `.borderedProminent`/`.bordered` otherwise fall back to the
        // system accent color, not the theme.
        .tint(theme.primaryColor)
        .padding(.horizontal, 28)
        .padding(.top, 8)
        // Clearance for the page control iOS overlays on the bottom of a
        // paged TabView; it reserves no layout space of its own.
        .padding(.bottom, 50)
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
