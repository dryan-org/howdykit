import Foundation
import Testing
@testable import HowdyKit

@Suite("Onboarding flow")
struct OnboardingFlowTests {
    private func makeStorage() -> UserDefaultsOnboardingStorage {
        let defaults = UserDefaults(suiteName: "howdykit-tests-\(UUID().uuidString)")!
        return UserDefaultsOnboardingStorage(defaults: defaults)
    }

    private let health = OnboardingStepID("com.dryan.crumbdb.reqs.health")
    private let location = OnboardingStepID("com.dryan.crumbdb.reqs.location")
    private let photos = OnboardingStepID("com.dryan.crumbdb.reqs.photos")
    private let localNetwork = OnboardingStepID("com.dryan.crumbdb.reqs.local-network")

    private func threeStepFlow(storage: any OnboardingStorage) -> OnboardingFlow {
        OnboardingFlow(
            steps: [
                OnboardingStepConfig(id: health, isRequired: false),
                OnboardingStepConfig(id: location, isRequired: true),
                OnboardingStepConfig(id: photos, isRequired: true),
            ],
            storage: storage
        )
    }

    @Test("A brand-new user needs onboarding, starting at the first step")
    func freshUserNeedsFirstStep() {
        let flow = threeStepFlow(storage: makeStorage())
        #expect(flow.needsOnboarding)
        #expect(flow.nextStepNeeded?.id == health)
    }

    @Test("Once every step has an answer, nothing is left to show")
    func fullyAnsweredNeedsNothing() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.record(true, for: health)
        flow.record(true, for: location)
        flow.record(false, for: photos)
        #expect(!flow.needsOnboarding)
        #expect(flow.nextStepNeeded == nil)
    }

    @Test("A step added after a user already onboarded shows only that step")
    func newStepAddedLaterShowsOnlyItself() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.record(true, for: health)
        flow.record(true, for: location)
        flow.record(true, for: photos)
        #expect(!flow.needsOnboarding)

        // A year later, local-network joins the flow. This returning user
        // has no record for it at all.
        let updatedFlow = OnboardingFlow(
            steps: flow.steps + [OnboardingStepConfig(id: localNetwork, isRequired: false)],
            storage: storage
        )
        #expect(updatedFlow.needsOnboarding)
        #expect(updatedFlow.nextStepNeeded?.id == localNetwork)
    }

    @Test("Required steps must be true, not just answered, to be satisfied")
    func requiredMustBeGranted() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.record(false, for: health) // optional, declined
        flow.record(true, for: location) // required, granted
        flow.record(false, for: photos) // required, declined
        #expect(!flow.needsOnboarding) // every step has *an* answer
        #expect(!flow.allRequiredSatisfied) // but photos is required and declined

        flow.record(true, for: photos)
        #expect(flow.allRequiredSatisfied)
    }

    @Test("Leaving a skippable step with no answer counts as skipped")
    func leavingSkippableStepRecordsFalse() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.recordIfNeeded(leaving: health, isSkippable: true)
        #expect(flow.value(for: health) == false)
    }

    @Test("Leaving a non-skippable step with no answer counts as acknowledged")
    func leavingNonSkippableStepRecordsTrue() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.recordIfNeeded(leaving: health, isSkippable: false)
        #expect(flow.value(for: health) == true)
    }

    @Test("A real answer is never overwritten by the leaving backfill")
    func leavingDoesNotOverwriteARealAnswer() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.record(true, for: health)
        flow.recordIfNeeded(leaving: health, isSkippable: true)
        #expect(flow.value(for: health) == true)
    }
}

@Suite("UserDefaults storage")
struct UserDefaultsOnboardingStorageTests {
    private let stepID = OnboardingStepID("com.dryan.crumbdb.reqs.health")

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "howdykit-tests-\(UUID().uuidString)")!
    }

    @Test("An unrecorded step reads as nil")
    func unrecordedIsNil() {
        let storage = UserDefaultsOnboardingStorage(defaults: makeDefaults())
        #expect(storage.value(for: stepID) == nil)
    }

    @Test("Setting nil clears a record back to unrecorded")
    func settingNilClears() {
        let storage = UserDefaultsOnboardingStorage(defaults: makeDefaults())
        storage.setValue(true, for: stepID)
        storage.setValue(nil, for: stepID)
        #expect(storage.value(for: stepID) == nil)
    }

    @Test("Two prefixes in the same suite never collide")
    func prefixesIsolate() {
        let defaults = makeDefaults()
        let crumbdb = UserDefaultsOnboardingStorage(defaults: defaults, keyPrefix: "crumbdb.")
        let marie = UserDefaultsOnboardingStorage(defaults: defaults, keyPrefix: "marie.")
        crumbdb.setValue(true, for: stepID)
        #expect(crumbdb.value(for: stepID) == true)
        #expect(marie.value(for: stepID) == nil)
    }
}
