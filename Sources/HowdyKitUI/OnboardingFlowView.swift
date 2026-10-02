import HowdyKit
import SwiftUI

/// Shows the flow's welcome first when it still needs one, then sequences
/// the steps `flow` still needs, in order, as a paged container. This is the turnkey piece: an app hands it a step's content and gets
/// paging, swipe-past backfill, and completion for free, so CrumbDB, Marie,
/// and anything after them share the same flow mechanics, not just the same
/// per-step look.
///
/// The pending step list is captured once, at init. Steps already answered
/// when the flow starts never appear; a step answered *during* the flow
/// (via its own `OnboardingAction`) doesn't resize the page count out from
/// under an in-progress swipe, it's just skipped over on `advance()`.
public struct OnboardingFlowView<Welcome: View, StepContent: View>: View {
    private let flow: OnboardingFlow
    private let welcome: (() -> Welcome)?
    private let pendingSteps: [OnboardingStepConfig]
    private let onFinished: () -> Void
    private let stepContent: (OnboardingStepConfig, @escaping () -> Void) -> StepContent

    @State private var currentIndex = 0
    @State private var highestVisitedIndex = 0

    /// - Parameter welcome: builds the welcome screen, shown while
    ///   `flow.needsWelcome`. Typically an `OnboardingWelcomeView`, which
    ///   records the welcome itself.
    /// - Parameter stepContent: builds one step's view, given the step and
    ///   an `advance` closure the step's own primary action calls after
    ///   recording its answer. The container doesn't record answers itself,
    ///   only the swipe-past backfill on `OnboardingFlow`.
    public init(
        flow: OnboardingFlow,
        onFinished: @escaping () -> Void = {},
        @ViewBuilder welcome: @escaping () -> Welcome,
        @ViewBuilder stepContent: @escaping (OnboardingStepConfig, @escaping () -> Void) -> StepContent
    ) {
        self.flow = flow
        self.welcome = welcome
        self.onFinished = onFinished
        self.stepContent = stepContent
        self.pendingSteps = flow.steps.filter { flow.value(for: $0.id) == nil }
    }

    public var body: some View {
        // No state of its own: recording the welcome bumps the flow's change
        // token, which `needsWelcome` reads, so this re-renders by itself.
        if flow.needsWelcome, let welcome {
            welcome()
        } else if pendingSteps.isEmpty {
            Color.clear.onAppear(perform: onFinished)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(pendingSteps.enumerated()), id: \.element.id) { index, step in
                    stepContent(step, advance)
                        // Explicit identity per step. Every page shares one
                        // opaque `StepContent` type (a single closure builds
                        // them all), so without this SwiftUI may diff
                        // adjacent pages as one conditional view changing
                        // content. Added while chasing a crossed-over page
                        // slide; not yet confirmed as the cause.
                        .id(step.id.rawValue)
                        .tag(index)
                }
            }
            #if os(iOS)
            // `.automatic` shows the page dots CrumbDB's own onboarding
            // already has (and hides them for a single pending step), not
            // suppress them - `.never` also leaves the space iOS reserves
            // for the control empty instead of actually removing it.
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            #endif
            .onChange(of: currentIndex) { _, newIndex in
                // A swipe can only move one page, but handle a programmatic
                // jump of more than one too: backfill every step passed over.
                guard newIndex > highestVisitedIndex else { return }
                for passedIndex in highestVisitedIndex..<newIndex {
                    let step = pendingSteps[passedIndex]
                    flow.recordIfNeeded(leaving: step)
                }
                highestVisitedIndex = newIndex
            }
        }
    }

    private func advance() {
        if currentIndex + 1 < pendingSteps.count {
            currentIndex += 1
        } else {
            onFinished()
        }
    }
}

extension OnboardingFlowView where Welcome == EmptyView {
    /// A flow with no welcome screen: goes straight to the steps.
    public init(
        flow: OnboardingFlow,
        onFinished: @escaping () -> Void = {},
        @ViewBuilder stepContent: @escaping (OnboardingStepConfig, @escaping () -> Void) -> StepContent
    ) {
        self.flow = flow
        self.welcome = nil
        self.onFinished = onFinished
        self.stepContent = stepContent
        self.pendingSteps = flow.steps.filter { flow.value(for: $0.id) == nil }
    }
}
