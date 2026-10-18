import HowdyKit
import SwiftUI
import Testing

@testable import HowdyKitUI

@MainActor
@Suite("OnboardingActions")
struct OnboardingActionsTests {
    private func actions(
        _ primary: LocalizedStringKey = "Next",
        prominent: Bool = true,
        secondary: LocalizedStringKey? = nil,
        handler: @escaping () -> Void = {}
    ) -> OnboardingActions {
        OnboardingActions(
            primary: OnboardingAction(title: primary, isProminent: prominent, handler: handler),
            secondary: secondary.map { OnboardingAction(title: $0, handler: handler) }
        )
    }

    @Test func equalityIgnoresHandlers() {
        var calls = 0
        let a = actions(secondary: "Skip") {}
        let b = actions(secondary: "Skip") { calls += 1 }
        #expect(a == b)
        #expect(calls == 0)
    }

    @Test func differentTitleIsNotEqual() {
        #expect(actions("Next") != actions("Done"))
        #expect(actions(secondary: "Skip") != actions(secondary: "Later"))
    }

    @Test func differentProminenceIsNotEqual() {
        #expect(actions(prominent: true) != actions(prominent: false))
    }

    @Test func nilVersusNonNilSecondaryIsNotEqual() {
        #expect(actions(secondary: nil) != actions(secondary: "Skip"))
    }

    @Test func reduceMergesWithLaterValueWinning() {
        let first = OnboardingStepID("a")
        let second = OnboardingStepID("b")
        var value: [OnboardingStepID: OnboardingActions] = [
            first: actions("Old"),
            second: actions("Kept"),
        ]
        OnboardingActionsKey.reduce(value: &value) {
            [first: actions("New"), OnboardingStepID("c"): actions("Added")]
        }
        #expect(value.count == 3)
        #expect(value[first] == actions("New"))
        #expect(value[second] == actions("Kept"))
        #expect(value[OnboardingStepID("c")] == actions("Added"))
    }

    @Test func defaultPreferenceValueIsEmpty() {
        #expect(OnboardingActionsKey.defaultValue.isEmpty)
    }

    @Test func stepIDEnvironmentDefaultsToNilAndRoundTrips() {
        var env = EnvironmentValues()
        #expect(env.onboardingStepID == nil)
        env.onboardingStepID = OnboardingStepID("welcome")
        #expect(env.onboardingStepID == OnboardingStepID("welcome"))
    }
}

@MainActor
@Suite("OnboardingFlowView footer identity")
struct OnboardingFooterIdentityTests {
    @Test func samePublishedTitlesStillGiveEachPageItsOwnFooter() {
        let analytics = OnboardingStepID("analytics")
        let notifications = OnboardingStepID("notifications")
        var ran: [String] = []
        func published(_ name: String) -> OnboardingActions {
            OnboardingActions(
                primary: OnboardingAction(title: "Allow", handler: { ran.append(name) }),
                secondary: OnboardingAction(title: "Skip", handler: {})
            )
        }
        let a = published("analytics")
        let n = published("notifications")
        // The premise: equality cannot tell the pages apart, so the footer's inputs compare equal.
        #expect(a == n)
        // The fix: the footer is keyed on the page, so the buttons rebind on every page change.
        let flowType = OnboardingFlowView<EmptyView, EmptyView>.self
        #expect(flowType.footerIdentity(for: analytics) != flowType.footerIdentity(for: notifications))
        #expect(flowType.footerIdentity(for: nil) != flowType.footerIdentity(for: analytics))
        // The page's own handler is the one its published actions carry.
        n.primary.handler()
        #expect(ran == ["notifications"])
    }
}
