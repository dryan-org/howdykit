import HowdyKit

/// One page of an `OnboardingFlowView`: the welcome (no step config, keyed
/// by the flow's `welcomeID`) or a step.
struct OnboardingFlowPage: Equatable {
    let id: OnboardingStepID
    let step: OnboardingStepConfig?

    var isWelcome: Bool { step == nil }

    /// The pages a flow still needs, welcome first when it's wanted and
    /// unrecorded, then every unanswered step in declaration order. Reads
    /// `storage` directly rather than the flow's tracked queries: this runs
    /// inside a parent view's body, and tracking there would re-render the
    /// parent on every answer for no reason.
    static func pending(in flow: OnboardingFlow, includeWelcome: Bool) -> [OnboardingFlowPage] {
        var pages: [OnboardingFlowPage] = []
        if includeWelcome, let welcomeID = flow.welcomeID, flow.storage.value(for: welcomeID) == nil {
            pages.append(OnboardingFlowPage(id: welcomeID, step: nil))
        }
        for step in flow.steps where flow.storage.value(for: step.id) == nil {
            pages.append(OnboardingFlowPage(id: step.id, step: step))
        }
        return pages
    }
}
