/// One step's identity and whether it blocks a flow from completing.
/// Everything else about a step (header, content, actions, theme) belongs to
/// the view layer, not here - this type only carries what the storage layer
/// and flow queries need.
public struct OnboardingStepConfig: Hashable, Sendable {
    public let id: OnboardingStepID
    public let isRequired: Bool

    public init(id: OnboardingStepID, isRequired: Bool) {
        self.id = id
        self.isRequired = isRequired
    }
}
