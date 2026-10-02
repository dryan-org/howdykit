/// Ties a step list to storage and answers the questions a flow (or a
/// one-line platform check, like a watch target) actually needs: is there
/// anything left to show, what's the next thing to show, and has everything
/// required been satisfied.
public struct OnboardingFlow: Sendable {
    public let steps: [OnboardingStepConfig]
    public let storage: any OnboardingStorage

    public init(steps: [OnboardingStepConfig], storage: any OnboardingStorage) {
        self.steps = steps
        self.storage = storage
    }

    /// True while any step, required or not, has never been recorded. This
    /// is the entire watchOS surface: a platform that only needs "show real
    /// content or tell them to finish on their phone" asks this and nothing
    /// else from the kit.
    public var needsOnboarding: Bool {
        steps.contains { storage.value(for: $0.id) == nil }
    }

    /// The first step with no record yet, in declaration order. A brand-new
    /// user gets the first step in the list; a returning user whose only
    /// gap is a step added since they last onboarded gets just that one.
    public var nextStepNeeded: OnboardingStepConfig? {
        steps.first { storage.value(for: $0.id) == nil }
    }

    /// Whether every required step has an affirmative record. Drives
    /// whether a flow's closing action (CrumbDB's "Get Started") may fire -
    /// a step answered `false` (denied/declined) still counts as answered
    /// for `needsOnboarding`, but not as satisfied here.
    public var allRequiredSatisfied: Bool {
        steps.filter(\.isRequired).allSatisfy { storage.value(for: $0.id) == true }
    }

    public func value(for id: OnboardingStepID) -> Bool? {
        storage.value(for: id)
    }

    public func record(_ value: Bool, for id: OnboardingStepID) {
        storage.setValue(value, for: id)
    }

    /// Call when a step is being left (by its own button or by a swipe past
    /// it) and it may still be unanswered. Writing nothing on a swipe past
    /// would make the step look never-seen and show it again later, so this
    /// backfills the step's default the one time its record is still nil;
    /// it does nothing once a real answer exists.
    ///
    /// `isSkippable` picks the default: a step with no skip path (welcome)
    /// only has one way to leave it, so that counts as `true`. A step that
    /// does offer skip treats leaving it unanswered the same as tapping
    /// Skip, `false`.
    public func recordIfNeeded(leaving id: OnboardingStepID, isSkippable: Bool) {
        guard storage.value(for: id) == nil else { return }
        storage.setValue(!isSkippable, for: id)
    }
}
