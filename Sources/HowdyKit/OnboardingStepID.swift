/// Identifies one step across app versions. Reverse-DNS by convention
/// (`com.dryan.crumbdb.reqs.health`) so records never collide across apps if
/// they ever land in a shared place, and so a step added a year from now
/// (`com.dryan.crumbdb.reqs.local-network`) is a new, unrecognized ID rather
/// than colliding with anything already stored.
///
/// Required-ness is deliberately not part of the ID. It lives on
/// `OnboardingStepConfig` instead, looked up by ID, so flipping a step
/// between required and optional later never orphans existing records.
public struct OnboardingStepID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension OnboardingStepID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
