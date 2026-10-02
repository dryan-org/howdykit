import HowdyKit
import SwiftUI

/// The first-run screen: no header/content split, no skip, just whatever
/// hero layout an app wants and a single action. Still a turnkey
/// `HowdyKitUI` type, themed from the environment (`.onboardingTheme(_:)`, set
/// once at the app's root) and wired to `OnboardingFlow` the same as every
/// other step, it just doesn't force `OnboardingStepView`'s structure on a
/// screen that's usually more custom (a brand intro, an app icon, a short
/// pitch) than a step with a title and two buttons.
///
/// Records `true` for the flow's `welcomeID` when the action fires, there's
/// no second storage mechanism and no way to leave this screen unanswered.
/// The flow must have been created with a welcome ID.
///
/// Draws the hero content only and publishes its action under the
/// `welcomeID`; `OnboardingFlowView` renders the footer, so Continue sits
/// where Next will on the next screen.
public struct OnboardingWelcomeView<Content: View>: View {
    private let flow: OnboardingFlow
    private let welcomeID: OnboardingStepID
    @Environment(\.onboardingTheme) private var theme
    private let actionTitle: LocalizedStringKey
    private let content: Content
    private let onContinue: () -> Void

    public init(
        flow: OnboardingFlow,
        actionTitle: LocalizedStringKey = "Continue",
        @ViewBuilder content: () -> Content,
        onContinue: @escaping () -> Void = {}
    ) {
        precondition(flow.welcomeID != nil, "OnboardingWelcomeView needs a flow created with a welcome ID")
        self.flow = flow
        self.welcomeID = flow.welcomeID!
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
        }
        .background(theme.background.ignoresSafeArea())
        .preference(
            key: OnboardingActionsKey.self,
            value: [
                welcomeID: OnboardingActions(
                    primary: OnboardingAction(title: actionTitle) {
                        flow.record(true, for: welcomeID)
                        onContinue()
                    }
                )
            ]
        )
    }
}
