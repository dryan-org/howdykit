import HowdyKit
import SwiftUI

/// What a page wants in the shared footer. Published upward by
/// `OnboardingStepView`/`OnboardingWelcomeView`; rendered once, below the
/// TabView, by `OnboardingFlowView`.
public struct OnboardingActions: Equatable {
    public var primary: OnboardingAction
    public var secondary: OnboardingAction?
    /// Whether the footer shows the buttons. A page that stages its entrance (the welcome, fading its
    /// buttons in after its title) publishes `false` first and `true` when they should appear; the footer
    /// fades between the two, and hidden buttons take no taps.
    public var isRevealed: Bool

    public init(primary: OnboardingAction, secondary: OnboardingAction? = nil, isRevealed: Bool = true) {
        self.primary = primary
        self.secondary = secondary
        self.isRevealed = isRevealed
    }

    // Equality ignores handlers: titles and prominence are what the footer
    // renders, and a handler built in the same render captures the same
    // state, so a stale one still reads current values.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isRevealed == rhs.isRevealed
            && lhs.primary.title == rhs.primary.title
            && lhs.primary.isProminent == rhs.primary.isProminent
            && lhs.secondary?.title == rhs.secondary?.title
            && lhs.secondary?.isProminent == rhs.secondary?.isProminent
    }
}

struct OnboardingActionsKey: PreferenceKey {
    static let defaultValue: [OnboardingStepID: OnboardingActions] = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

extension EnvironmentValues {
    /// The step a page is showing, so it knows which key to publish under.
    /// `nil` outside an `OnboardingFlowView`.
    @Entry var onboardingStepID: OnboardingStepID? = nil

    /// Whether the page is the one on screen in its `OnboardingFlowView`; `true` outside a flow. A page that
    /// plays something on arrival (the header icon's draw-on) starts when this turns `true` and rearms when it
    /// turns `false`.
    @Entry var onboardingPageIsCurrent: Bool = true
}
