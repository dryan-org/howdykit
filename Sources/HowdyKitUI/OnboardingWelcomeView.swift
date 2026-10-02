import HowdyKit
import SwiftUI

/// The first-run screen: no header/content split, no skip, just whatever
/// hero layout an app wants and a single action. Still a turnkey
/// `HowdyKitUI` type, themed and wired to `OnboardingFlow` the same as every
/// other step, it just doesn't force `OnboardingStepView`'s structure on a
/// screen that's usually more custom (a brand intro, an app icon, a short
/// pitch) than a step with a title and two buttons.
///
/// Records `true` for `stepID` itself when the action fires, there's no
/// second storage mechanism and no way to leave this screen unanswered.
public struct OnboardingWelcomeView<Content: View>: View {
    private let flow: OnboardingFlow
    private let stepID: OnboardingStepID
    private let theme: OnboardingTheme
    private let actionTitle: LocalizedStringKey
    private let content: Content
    private let onContinue: () -> Void

    public init(
        flow: OnboardingFlow,
        stepID: OnboardingStepID,
        theme: OnboardingTheme = .default,
        actionTitle: LocalizedStringKey = "Continue",
        @ViewBuilder content: () -> Content,
        onContinue: @escaping () -> Void = {}
    ) {
        self.flow = flow
        self.stepID = stepID
        self.theme = theme
        self.actionTitle = actionTitle
        self.content = content()
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView {
                    content
                        .padding(24)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
            Button(actionTitle) {
                flow.record(true, for: stepID)
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(theme.background.ignoresSafeArea())
    }
}
