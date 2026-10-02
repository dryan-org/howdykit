import SwiftUI

/// One step: an optional header, arbitrary content, and up to two actions,
/// themed by the app that composes it. This is the whole per-step template;
/// sequencing multiple steps into a flow (swipeable pages, a push stack,
/// whatever a platform needs) is left to the app, not owned here.
public struct OnboardingStepView<Content: View>: View {
    private let theme: OnboardingTheme
    private let header: OnboardingHeader?
    private let primaryAction: OnboardingAction
    private let secondaryAction: OnboardingAction?
    private let content: Content

    public init(
        theme: OnboardingTheme = .default,
        header: OnboardingHeader? = nil,
        primaryAction: OnboardingAction,
        secondaryAction: OnboardingAction? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
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

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 4) {
            Group {
                if primaryAction.isProminent {
                    primaryButton.buttonStyle(.borderedProminent)
                } else {
                    primaryButton.buttonStyle(.bordered)
                }
            }
            .controlSize(.large)

            if let secondaryAction {
                Button(secondaryAction.title, action: secondaryAction.handler)
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(theme.primaryColor.opacity(0.85))
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var primaryButton: some View {
        Button(action: primaryAction.handler) {
            Text(primaryAction.title)
                .frame(maxWidth: .infinity)
        }
    }
}
