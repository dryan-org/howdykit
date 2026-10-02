import HowdyKit
import SwiftUI

/// One step: an optional header, arbitrary content, and up to two actions,
/// themed from the environment (`.onboardingTheme(_:)`, set once at the app's
/// root). This renders a single step only;
/// `OnboardingFlowView` sequences a list of these into an actual flow.
///
/// Inside an `OnboardingFlowView` the view draws header and content only and
/// publishes its actions upward; the flow renders them once, below the
/// pages. Used on its own (no flow around it), it draws its own footer.
public struct OnboardingStepView<Content: View>: View {
    @Environment(\.onboardingTheme) private var theme
    @Environment(\.onboardingStepID) private var stepID
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
                    card
                    .padding(24)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
            if stepID == nil {
                OnboardingFooter(actions: OnboardingActions(primary: primaryAction, secondary: secondaryAction))
            }
        }
        .background(theme.background.ignoresSafeArea())
        .preference(key: OnboardingActionsKey.self, value: publishedActions)
    }

    @ViewBuilder
    private var card: some View {
        if let cardBackground = theme.cardBackground {
            stack
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
        } else {
            stack
        }
    }

    private var stack: some View {
        VStack(spacing: 20) {
            if let header {
                headerView(header)
            }
            content
        }
    }

    @ViewBuilder
    private func headerView(_ header: OnboardingHeader) -> some View {
        VStack(spacing: 10) {
            if let icon = header.icon {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(theme.accentColor)
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

    private var publishedActions: [OnboardingStepID: OnboardingActions] {
        guard let stepID else { return [:] }
        return [stepID: OnboardingActions(primary: primaryAction, secondary: secondaryAction)]
    }
}
