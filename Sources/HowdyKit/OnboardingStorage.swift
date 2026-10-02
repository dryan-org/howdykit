import Foundation

/// Reads and writes one step's tri-state record: `nil` (never recorded, so
/// the step has never been shown or answered), `true` (seen and granted /
/// completed / acknowledged), or `false` (seen and declined / skipped).
///
/// `nil` is the whole mechanism behind adding a step later: a returning user
/// has real records for every step that existed when they onboarded and
/// `nil` for one added since, so `OnboardingFlow.nextStepNeeded` finds only
/// the new one without any separate migration step.
public protocol OnboardingStorage: Sendable {
    func value(for id: OnboardingStepID) -> Bool?
    func setValue(_ value: Bool?, for id: OnboardingStepID)
}

/// The default storage: one `UserDefaults` suite, one key per step. Shares
/// naturally across an app and its same-device extensions/widgets when given
/// an App Group suite. Does not sync to a paired Watch on its own - that's a
/// genuinely separate device with its own sandbox, and needs either
/// `NSUbiquitousKeyValueStore` or `WatchConnectivity`, not App Groups.
// UserDefaults is thread-safe in practice (Apple documents it as such) but
// isn't marked Sendable by the SDK. Safe to assert here since every access
// goes through its own synchronized API, nothing is cached across calls.
public final class UserDefaultsOnboardingStorage: OnboardingStorage, @unchecked Sendable {
    private let defaults: UserDefaults
    private let keyPrefix: String

    /// `keyPrefix` is prepended to every step's raw ID to form its storage
    /// key, so one `UserDefaults` suite can safely hold more than one app's
    /// (or one flow's) records without collisions.
    public init(defaults: UserDefaults = .standard, keyPrefix: String = "") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    private func key(for id: OnboardingStepID) -> String {
        keyPrefix + id.rawValue
    }

    public func value(for id: OnboardingStepID) -> Bool? {
        let key = key(for: id)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.bool(forKey: key)
    }

    public func setValue(_ value: Bool?, for id: OnboardingStepID) {
        let key = key(for: id)
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
