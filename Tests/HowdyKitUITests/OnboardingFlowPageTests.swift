import Foundation
import HowdyKit
import Testing
@testable import HowdyKitUI

@Suite("OnboardingFlowPage.pending")
struct OnboardingFlowPageTests {
    private let welcome = OnboardingStepID("com.dryan.test.welcome")
    private let first = OnboardingStepID("com.dryan.test.first")
    private let middle = OnboardingStepID("com.dryan.test.middle")
    private let last = OnboardingStepID("com.dryan.test.last")

    private func makeFlow(welcome: OnboardingStepID?) -> OnboardingFlow {
        let defaults = UserDefaults(suiteName: "howdykit-ui-tests-\(UUID().uuidString)")!
        return OnboardingFlow(
            welcome: welcome,
            steps: [
                OnboardingStepConfig(id: first, isRequired: false, isSkippable: false),
                OnboardingStepConfig(id: middle, isRequired: true),
                OnboardingStepConfig(id: last, isRequired: false),
            ],
            storage: UserDefaultsOnboardingStorage(defaults: defaults)
        )
    }

    @Test("A fresh flow pages the welcome first, then every step in order")
    func freshFlowStartsWithWelcome() {
        let pages = OnboardingFlowPage.pending(in: makeFlow(welcome: welcome), includeWelcome: true)
        #expect(pages.map(\.id) == [welcome, first, middle, last])
        #expect(pages.first?.isWelcome == true)
        #expect(pages.dropFirst().allSatisfy { !$0.isWelcome })
    }

    @Test("A recorded welcome, or a view without one, leaves the welcome out")
    func welcomeOmittedWhenRecordedOrNotWanted() {
        let flow = makeFlow(welcome: welcome)
        #expect(OnboardingFlowPage.pending(in: flow, includeWelcome: false).map(\.id) == [first, middle, last])
        flow.record(true, for: welcome)
        #expect(OnboardingFlowPage.pending(in: flow, includeWelcome: true).map(\.id) == [first, middle, last])
        #expect(OnboardingFlowPage.pending(in: makeFlow(welcome: nil), includeWelcome: true).map(\.id) == [first, middle, last])
    }

    @Test("An answered step in the middle drops out without reordering the rest")
    func answeredMiddleStepIsSkipped() {
        let flow = makeFlow(welcome: welcome)
        flow.record(true, for: welcome)
        flow.record(false, for: middle)
        let pages = OnboardingFlowPage.pending(in: flow, includeWelcome: true)
        #expect(pages.map(\.id) == [first, last])
        #expect(pages.compactMap(\.step?.id) == [first, last])
    }

    @Test("Moving forward passes every index left behind; standing still or going back passes none")
    func indicesPassed() {
        #expect(Array(OnboardingFlowPage.indicesPassed(from: 0, to: 1)) == [0])
        #expect(Array(OnboardingFlowPage.indicesPassed(from: 1, to: 3)) == [1, 2])
        #expect(OnboardingFlowPage.indicesPassed(from: 2, to: 1).isEmpty)
        #expect(OnboardingFlowPage.indicesPassed(from: 2, to: 2).isEmpty)
    }

    @Test("A page is reported when it is new, never twice in a row, and never when absent")
    func nextShownGuard() {
        #expect(OnboardingFlowPage.nextShown(first, after: nil) == first)
        #expect(OnboardingFlowPage.nextShown(middle, after: first) == middle)
        #expect(OnboardingFlowPage.nextShown(first, after: first) == nil)
        #expect(OnboardingFlowPage.nextShown(nil, after: first) == nil)
        #expect(OnboardingFlowPage.nextShown(nil, after: nil) == nil)
    }
}
