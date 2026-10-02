import HowdyKit
import SwiftUI

/// Sequences the steps `flow` still needs, in order, as a paged container.
/// This is the turnkey piece: an app hands it a step's content and gets
/// paging, swipe-past backfill, and completion for free, so CrumbDB, Marie,
/// and anything after them share the same flow mechanics, not just the same
/// per-step look.
///
/// The pending step list is captured once, at init. Steps already answered
/// when the flow starts never appear; a step answered *during* the flow
/// (via its own `OnboardingAction`) doesn't resize the page count out from
/// under an in-progress swipe, it's just skipped over on `advance()`.
public struct OnboardingFlowView<StepContent: View>: View {
    private let flow: OnboardingFlow
    private let pendingSteps: [OnboardingStepConfig]
    private let onFinished: () -> Void
    private let stepContent: (OnboardingStepConfig, @escaping () -> Void) -> StepContent

    @State private var currentIndex = 0
    @State private var highestVisitedIndex = 0

    /// - Parameter stepContent: builds one step's view, given the step and
    ///   an `advance` closure the step's own primary action calls after
    ///   recording its answer. The container doesn't record answers itself,
    ///   only the swipe-past backfill on `OnboardingFlow`.
    public init(
        flow: OnboardingFlow,
        onFinished: @escaping () -> Void = {},
        @ViewBuilder stepContent: @escaping (OnboardingStepConfig, @escaping () -> Void) -> StepContent
    ) {
        self.flow = flow
        self.onFinished = onFinished
        self.stepContent = stepContent
        self.pendingSteps = flow.steps.filter { flow.value(for: $0.id) == nil }
    }

    public var body: some View {
        if pendingSteps.isEmpty {
            Color.clear.onAppear(perform: onFinished)
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(pendingSteps.enumerated()), id: \.element.id) { index, step in
                    stepContent(step, advance)
                        .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .onChange(of: currentIndex) { newIndex in
                // A swipe can only move one page, but handle a programmatic
                // jump of more than one too: backfill every step passed over.
                guard newIndex > highestVisitedIndex else { return }
                for passedIndex in highestVisitedIndex..<newIndex {
                    let step = pendingSteps[passedIndex]
                    flow.recordIfNeeded(leaving: step.id, isSkippable: !step.isRequired)
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
