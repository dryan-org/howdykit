import Observation

/// Ties a step list to storage and answers the questions a flow (or a
/// one-line platform check, like a watch target) actually needs: is there
/// anything left to show, what's the next thing to show, and has everything
/// required been satisfied.
///
/// `@Observable`, not a plain value type: the real data lives behind
/// `storage` (plain `UserDefaults` by default), which Observation can't see
/// into on its own. `record`/`recordIfNeeded` bump `changeToken`, and every
/// query reads it first purely so Observation's access tracking registers a
/// dependency on it - that's what lets a view just read `flow.needsWelcome`
/// (or any other query) and have it actually re-render after a write,
/// instead of every app having to hand-roll its own local `@State` mirror of
/// "have I seen this yet."
///
/// Not `Sendable`: like any `@Observable` type, it's meant to be read and
/// written from one isolation context (the UI's), not shared across them.
@Observable
public final class OnboardingFlow {
    /// The welcome screen's ID, when the flow has one. The flow tracks its
    /// record like any step's, but never pages it: it isn't in `steps`, so
    /// it is shown once, first, with no skip, and `nextStepNeeded` ignores it.
    public let welcomeID: OnboardingStepID?
    public let steps: [OnboardingStepConfig]
    @ObservationIgnored public let storage: any OnboardingStorage

    private var changeToken = 0

    public init(
        welcome: OnboardingStepID? = nil,
        steps: [OnboardingStepConfig],
        storage: any OnboardingStorage
    ) {
        self.welcomeID = welcome
        self.steps = steps
        self.storage = storage
    }

    /// True when the flow has a welcome ID and it has never been recorded.
    /// Always false for a flow created without `welcome:`.
    public var needsWelcome: Bool {
        _ = changeToken
        guard let welcomeID else { return false }
        return storage.value(for: welcomeID) == nil
    }

    /// True while the welcome (if any) or any step, required or not, has
    /// never been recorded. This is the entire watchOS surface: a platform
    /// that only needs "show real content or tell them to finish on their
    /// phone" asks this and nothing else from the kit.
    public var needsOnboarding: Bool {
        needsWelcome || steps.contains { storage.value(for: $0.id) == nil }
    }

    /// The first step with no record yet, in declaration order. The welcome
    /// is not a step, so it never appears here. A brand-new
    /// user gets the first step in the list; a returning user whose only
    /// gap is a step added since they last onboarded gets just that one.
    public var nextStepNeeded: OnboardingStepConfig? {
        _ = changeToken
        return steps.first { storage.value(for: $0.id) == nil }
    }

    /// Whether every required step has an affirmative record. Drives
    /// whether a flow's closing action (CrumbDB's "Get Started") may fire -
    /// a step answered `false` (denied/declined) still counts as answered
    /// for `needsOnboarding`, but not as satisfied here.
    public var allRequiredSatisfied: Bool {
        _ = changeToken
        return steps.filter(\.isRequired).allSatisfy { storage.value(for: $0.id) == true }
    }

    public func value(for id: OnboardingStepID) -> Bool? {
        _ = changeToken
        return storage.value(for: id)
    }

    public func record(_ value: Bool, for id: OnboardingStepID) {
        storage.setValue(value, for: id)
        changeToken += 1
    }

    /// Call when a step is being left (by its own button or by a swipe past
    /// it) and it may still be unanswered. Writing nothing on a swipe past
    /// would make the step look never-seen and show it again later, so this
    /// backfills the step's default the one time its record is still nil;
    /// it does nothing once a real answer exists.
    ///
    /// `step.isSkippable` picks the default: a non-skippable step
    /// (acknowledge-only) has just one way to leave it, so that counts as
    /// `true`. A skippable step treats leaving it unanswered the same as
    /// tapping Skip, `false`, even when it's required (the flow then stays
    /// unsatisfied, see `allRequiredSatisfied`).
    public func recordIfNeeded(leaving step: OnboardingStepConfig) {
        guard storage.value(for: step.id) == nil else { return }
        storage.setValue(!step.isSkippable, for: step.id)
        changeToken += 1
    }

    /// Records `true` for every unanswered step that `isSatisfied` reports
    /// as already satisfied outside the flow (a system permission the OS
    /// already granted, say). Steps with an answer are left alone. Call it
    /// before presenting the flow, and again when the app returns to the
    /// foreground, since Settings may have changed a permission meanwhile.
    public func reconcile(isSatisfied: (OnboardingStepConfig) -> Bool) {
        var recorded = false
        for step in steps where storage.value(for: step.id) == nil && isSatisfied(step) {
            storage.setValue(true, for: step.id)
            recorded = true
        }
        // Only bump when something changed, so a no-op reconcile re-renders nothing.
        if recorded {
            changeToken += 1
        }
    }

    /// Clears one record back to unrecorded. Development/testing, like
    /// `reset`: lets a tool set up "this step was never seen" by itself.
    public func clear(_ id: OnboardingStepID) {
        storage.setValue(nil, for: id)
        changeToken += 1
    }

    /// Clears every step's record back to unrecorded, plus the welcome's when
    /// the flow has one, and any IDs in `additionalIDs` that an app stores
    /// alongside the flow without them being steps. For development/testing - a shipped
    /// onboarding flow has no in-product reason to see itself again, but
    /// every app building on this kit will want a way to replay it.
    public func reset(including additionalIDs: [OnboardingStepID] = []) {
        for step in steps {
            storage.setValue(nil, for: step.id)
        }
        if let welcomeID {
            storage.setValue(nil, for: welcomeID)
        }
        for id in additionalIDs {
            storage.setValue(nil, for: id)
        }
        changeToken += 1
    }
}
