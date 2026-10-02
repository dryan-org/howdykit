import Foundation
import Observation
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

    private let welcomeID = OnboardingStepID("com.dryan.crumbdb.welcome")

    private func threeStepFlow(
        welcome: OnboardingStepID? = nil,
        storage: any OnboardingStorage
    ) -> OnboardingFlow {
        OnboardingFlow(
            welcome: welcome,
            steps: [
                // Acknowledge-only: no skip path, not required.
                OnboardingStepConfig(id: health, isRequired: false, isSkippable: false),
                // Required permission steps that can still be declined.
                OnboardingStepConfig(id: location, isRequired: true, isSkippable: true),
                OnboardingStepConfig(id: photos, isRequired: true, isSkippable: true),
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

    private func step(_ id: OnboardingStepID, in flow: OnboardingFlow) -> OnboardingStepConfig {
        flow.steps.first { $0.id == id }!
    }

    @Test("Leaving a skippable step with no answer counts as skipped")
    func leavingSkippableStepRecordsFalse() {
        let flow = threeStepFlow(storage: makeStorage())
        flow.recordIfNeeded(leaving: step(photos, in: flow))
        #expect(flow.value(for: photos) == false)
    }

    @Test("Leaving a non-skippable step with no answer counts as acknowledged")
    func leavingNonSkippableStepRecordsTrue() {
        let flow = threeStepFlow(storage: makeStorage())
        flow.recordIfNeeded(leaving: step(health, in: flow))
        #expect(flow.value(for: health) == true)
    }

    @Test("Swiping past a required, skippable step records false and leaves the flow unsatisfied")
    func swipingPastRequiredSkippableStepStaysUnsatisfied() {
        let flow = threeStepFlow(storage: makeStorage())
        let locationStep = step(location, in: flow)
        #expect(locationStep.isRequired)
        #expect(locationStep.isSkippable)

        flow.recordIfNeeded(leaving: locationStep)

        #expect(flow.value(for: location) == false)
        #expect(!flow.allRequiredSatisfied)
    }

    @Test("A real answer is never overwritten by the leaving backfill")
    func leavingDoesNotOverwriteARealAnswer() {
        let flow = threeStepFlow(storage: makeStorage())
        flow.record(true, for: photos)
        flow.recordIfNeeded(leaving: step(photos, in: flow))
        #expect(flow.value(for: photos) == true)

        flow.record(false, for: health)
        flow.recordIfNeeded(leaving: step(health, in: flow))
        #expect(flow.value(for: health) == false)
    }

    @Test("Clear puts one step back to unrecorded and leaves the rest")
    func clearOneStep() {
        let storage = makeStorage()
        let flow = threeStepFlow(storage: storage)
        flow.record(true, for: health)
        flow.record(false, for: location)
        flow.clear(health)
        #expect(flow.value(for: health) == nil)
        #expect(flow.value(for: location) == false)
    }

    @Test("Reset clears every step, the welcome, and extra IDs")
    func resetClearsEverything() {
        let storage = makeStorage()
        let flow = threeStepFlow(welcome: welcomeID, storage: storage)
        let extra = OnboardingStepID("com.dryan.crumbdb.extra")
        flow.record(true, for: welcomeID)
        flow.record(true, for: health)
        flow.record(true, for: location)
        flow.record(true, for: photos)
        storage.setValue(true, for: extra)

        flow.reset(including: [extra])
        #expect(flow.needsWelcome)
        #expect(flow.needsOnboarding)
        #expect(flow.value(for: welcomeID) == nil)
        #expect(flow.value(for: extra) == nil)

        flow.record(true, for: welcomeID)
        flow.record(true, for: health)
        flow.reset()
        #expect(flow.needsWelcome)
        #expect(flow.value(for: welcomeID) == nil)
        #expect(flow.value(for: health) == nil)
    }

    @Test("A flow without a welcome never needs one")
    func noWelcomeNeverNeedsWelcome() {
        let flow = threeStepFlow(storage: makeStorage())
        #expect(flow.welcomeID == nil)
        #expect(!flow.needsWelcome)
    }

    @Test("A fresh flow with a welcome needs onboarding even when every step is answered")
    func welcomeAloneKeepsOnboardingOpen() {
        let flow = threeStepFlow(welcome: welcomeID, storage: makeStorage())
        flow.record(true, for: health)
        flow.record(true, for: location)
        flow.record(true, for: photos)
        #expect(flow.needsWelcome)
        #expect(flow.needsOnboarding)
    }

    @Test("Recording the welcome clears needsWelcome and, with steps answered, needsOnboarding")
    func recordingWelcomeFinishesOnboarding() {
        let flow = threeStepFlow(welcome: welcomeID, storage: makeStorage())
        flow.record(true, for: health)
        flow.record(true, for: location)
        flow.record(true, for: photos)

        flow.record(true, for: welcomeID)
        #expect(!flow.needsWelcome)
        #expect(!flow.needsOnboarding)
    }

    @Test("The next step needed ignores the welcome")
    func nextStepNeededIgnoresWelcome() {
        let flow = threeStepFlow(welcome: welcomeID, storage: makeStorage())
        #expect(flow.nextStepNeeded?.id == health)
    }

    private final class Flag: @unchecked Sendable {
        var value = false
    }

    @Test("Recording a step notifies Observation tracking of needsOnboarding")
    func recordingTriggersObservation() {
        let flow = threeStepFlow(storage: makeStorage())
        let flag = Flag()
        withObservationTracking({ _ = flow.needsOnboarding }, onChange: { flag.value = true })
        #expect(!flag.value)

        flow.record(true, for: health)
        #expect(flag.value)
    }

    @Test("Reconcile records true for satisfied unanswered steps and leaves the rest nil")
    func reconcileRecordsSatisfiedSteps() {
        let flow = threeStepFlow(storage: makeStorage())
        flow.reconcile { $0.id == location }
        #expect(flow.value(for: location) == true)
        #expect(flow.value(for: health) == nil)
        #expect(flow.value(for: photos) == nil)
    }

    @Test("Reconcile never changes an existing answer")
    func reconcileKeepsExistingAnswers() {
        let flow = threeStepFlow(storage: makeStorage())
        flow.record(false, for: photos)
        flow.reconcile { _ in true }
        #expect(flow.value(for: photos) == false)
        #expect(flow.value(for: health) == true)
        #expect(flow.value(for: location) == true)
    }

    @Test("Reconcile notifies Observation only when it records something")
    func reconcileNotifiesOnlyOnChange() {
        let flow = threeStepFlow(storage: makeStorage())
        let quiet = Flag()
        withObservationTracking({ _ = flow.needsOnboarding }, onChange: { quiet.value = true })
        flow.reconcile { _ in false }
        #expect(!quiet.value)

        let loud = Flag()
        withObservationTracking({ _ = flow.needsOnboarding }, onChange: { loud.value = true })
        flow.reconcile { $0.id == health }
        #expect(loud.value)
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
