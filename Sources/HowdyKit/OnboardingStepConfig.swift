/// One step's identity and how it behaves in a flow. Everything else about
/// a step (header, content, actions, theme) belongs to the view layer, not
/// here, this type only carries what the storage layer and flow queries need.
///
/// `isRequired` and `isSkippable` are independent:
/// - `isRequired`: the flow is not satisfied until this step is recorded
///   `true`.
/// - `isSkippable`: the step can be left unanswered (a Skip button, or a
///   swipe past it). Leaving it unanswered is the same as declining, so the
///   backfill records `false`. A step with `isSkippable == false` is
///   acknowledge-only (an info screen): there's only one way to leave it, so
///   leaving it records `true`.
///
/// A required permission step is normally skippable (the user may decline
/// and the app stays unsatisfied); a non-skippable step is normally not
/// required (it's just acknowledged).
public struct OnboardingStepConfig: Hashable, Sendable {
    public let id: OnboardingStepID
    public let isRequired: Bool
    public let isSkippable: Bool

    public init(id: OnboardingStepID, isRequired: Bool, isSkippable: Bool = true) {
        self.id = id
        self.isRequired = isRequired
        self.isSkippable = isSkippable
    }
}
