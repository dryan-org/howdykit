import HowdyKit
import SwiftUI

/// What a page wants in the shared footer. Published upward by
/// `OnboardingStepView`/`OnboardingWelcomeView`; rendered once, below the
/// TabView, by `OnboardingFlowView`.
public struct OnboardingActions: Equatable {
    public var primary: OnboardingAction
    public var secondary: OnboardingAction?

    public init(primary: OnboardingAction, secondary: OnboardingAction? = nil) {
        self.primary = primary
        self.secondary = secondary
    }

    // Equality ignores handlers: titles and prominence are what the footer
    // renders, and a handler built in the same render captures the same
    // state, so a stale one still reads current values.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.primary.title == rhs.primary.title
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
}
