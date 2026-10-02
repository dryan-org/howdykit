import SwiftUI

/// One step: an optional header, arbitrary content, and up to two actions,
/// themed from the environment (`.onboardingTheme(_:)`, set once at the app's
/// root). This renders a single step only;
/// `OnboardingFlowView` sequences a list of these into an actual flow.
public struct OnboardingStepView<Content: View>: View {
    @Environment(\.onboardingTheme) private var theme
    private let header: OnboardingHeader?
    private let primaryAction: OnboardingAction
    private let secondaryAction: OnboardingAction?
    private let content: Content

    public init(
        header: OnboardingHeader? = nil,
        primaryAction: OnboardingAction,
        secondaryAction: OnboardingAction? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        if let header {
                            headerView(header)
                        }
                        content
                    }
                    .padding(24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
            footer
        }
        .background(theme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func headerView(_ header: OnboardingHeader) -> some View {
        VStack(spacing: 10) {
            if let icon = header.icon {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(theme.primaryColor)
            }
            Text(header.title)
                .font(theme.titleFont)
                .foregroundStyle(theme.primaryColor)
                .multilineTextAlignment(.center)
            if let headline = header.headline {
                Text(headline)
                    .font(theme.headlineFont)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var footer: some View {
        OnboardingFooter(primary: primaryAction, secondary: secondaryAction)
    }
}
