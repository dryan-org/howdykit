import HowdyKit
import SwiftUI

/// Sequences everything `flow` still needs as one paged container: the
/// welcome first (when the flow has one and it's unrecorded), then each
/// unanswered step in order. This is the turnkey piece: an app hands it a
/// step's content and gets paging, swipe-past backfill, and completion for
/// free, so CrumbDB, Marie, and anything after them share the same flow
/// mechanics, not just the same per-step look.
///
/// The welcome is a real page, not a separate screen swapped out before the
/// pager, so Continue slides to the first step exactly like a swipe and the
/// user can swipe back to it.
///
/// The pager is a paging `ScrollView` (not `TabView(.page)`, whose
/// programmatic changes don't slide and whose dots can go missing). One
/// shared footer sits below the pages, with the kit's own page dots above
/// the buttons. Each page keeps owning its actions and state and publishes them
/// upward (`OnboardingActions`); this view draws the footer for the page
/// currently shown.
///
/// The page list is captured once, when the view first appears, and held in
/// `@State`. Pages already answered when the flow starts never appear; one
/// answered *during* the flow does not resize the page count out from under
/// the user (which would shift every index, drop pages, and hide the dots
/// once one page is left).
public struct OnboardingFlowView<Welcome: View, StepContent: View>: View {
    private let flow: OnboardingFlow
    private let welcome: (() -> Welcome)?
    private let onFinished: () -> Void
    private let isAlreadySatisfied: (OnboardingStepConfig) -> Bool
    private let stepContent: (OnboardingStepConfig, @escaping () -> Void) -> StepContent

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.onboardingTheme) private var theme
    @State private var actions: [OnboardingStepID: OnboardingActions] = [:]
    @State private var currentPageID: OnboardingStepID?
    @State private var highestVisitedIndex = 0
    // `init` runs on every parent re-render (and every recorded answer
    // re-renders the parent, the flow being observable); `@State` keeps the
    // first snapshot and ignores the later `initialValue`s.
    @State private var pages: [OnboardingFlowPage]

    /// - Parameter welcome: builds the welcome page, shown first while the
    ///   flow's welcome is unrecorded. Typically an `OnboardingWelcomeView`,
    ///   which records the welcome itself; this view then slides on.
    /// - Parameter isAlreadySatisfied: reports whether a step is already
    ///   satisfied outside the flow (a permission the OS already granted).
    ///   Such unanswered steps are recorded `true` via
    ///   `flow.reconcile(isSatisfied:)` and never get a page. Runs on every
    ///   init, so keep it cheap.
    /// - Parameter stepContent: builds one step's view, given the step and
    ///   an `advance` closure the step's own primary action calls after
    ///   recording its answer. The container doesn't record answers itself,
    ///   only the swipe-past backfill on `OnboardingFlow`.
    public init(
        flow: OnboardingFlow,
        onFinished: @escaping () -> Void = {},
        isAlreadySatisfied: @escaping (OnboardingStepConfig) -> Bool = { _ in false },
        @ViewBuilder welcome: @escaping () -> Welcome,
        @ViewBuilder stepContent: @escaping (OnboardingStepConfig, @escaping () -> Void) -> StepContent
    ) {
        self.flow = flow
        self.welcome = welcome
        self.onFinished = onFinished
        self.isAlreadySatisfied = isAlreadySatisfied
        self.stepContent = stepContent
        flow.reconcile(isSatisfied: isAlreadySatisfied)
        let pages = OnboardingFlowPage.pending(in: flow, includeWelcome: true)
        _pages = State(initialValue: pages)
        _currentPageID = State(initialValue: pages.first?.id)
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
            OnboardingPageIndicator(count: pages.count, current: currentIndex)
                .transaction { $0.animation = nil }
            footer
        }
        // The pages draw their own background; this covers the footer strip.
        .background(theme.background.ignoresSafeArea())
        .onPreferenceChange(OnboardingActionsKey.self) { actions = $0 }
        .onChange(of: scenePhase) { _, phase in
            // `pages` stays as captured: this only affects what shows next
            // time, and `advance()` already handles pages answered meanwhile.
            if phase == .active {
                flow.reconcile(isSatisfied: isAlreadySatisfied)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if pages.isEmpty {
            Color.clear.onAppear(perform: onFinished)
        } else {
            // A horizontal ScrollView takes its height from its content, so
            // the pages are sized from the slot the pager actually gets (the
            // GeometryReader fills whatever the VStack leaves above the dots
            // and footer). `containerRelativeFrame` measured against the
            // whole screen here and pushed the footer below the bottom edge.
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    // Not lazy: a handful of pages, created up front so none
                    // is created mid-slide.
                    HStack(spacing: 0) {
                        ForEach(pages, id: \.id) { page in
                            Group {
                                if let step = page.step {
                                    stepContent(step, advance)
                                } else if let welcome {
                                    welcome()
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .environment(\.onboardingStepID, page.id)
                            .id(page.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentPageID)
                .scrollIndicators(.hidden)
            }
            .onChange(of: currentPageID) { _, _ in
                // A swipe can only move one page, but handle a programmatic
                // jump of more than one too: backfill every page passed over.
                let newIndex = currentIndex
                for passedIndex in OnboardingFlowPage.indicesPassed(from: highestVisitedIndex, to: newIndex) {
                    backfill(pages[passedIndex])
                }
                highestVisitedIndex = max(highestVisitedIndex, newIndex)
            }
            // The welcome records itself (`OnboardingWelcomeView`); slide on
            // once it has, if it's still the page on screen.
            .onChange(of: flow.needsWelcome) { _, needsWelcome in
                if !needsWelcome, currentIndex == 0, pages[0].isWelcome {
                    advance()
                }
            }
        }
    }

    private var footer: some View {
        // One permanent view, never swapped for another, and never animated:
        // a page change is wrapped in `withAnimation`, and any animated change
        // in here would move the pages (and the dots at their bottom) while
        // they slide.
        OnboardingFooter(actions: currentActions)
            .transaction { $0.animation = nil }
    }

    private var currentIndex: Int {
        pages.firstIndex { $0.id == currentPageID } ?? 0
    }

    private var currentActions: OnboardingActions? {
        guard pages.indices.contains(currentIndex) else { return nil }
        return actions[pages[currentIndex].id]
    }

    private func advance() {
        if currentIndex + 1 < pages.count {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPageID = pages[currentIndex + 1].id
            }
        } else {
            onFinished()
        }
    }

    /// Leaving a page unanswered: a step gets its `isSkippable` default, the
    /// welcome (which has no skip path) counts as seen.
    private func backfill(_ page: OnboardingFlowPage) {
        if let step = page.step {
            flow.recordIfNeeded(leaving: step)
        } else if flow.value(for: page.id) == nil {
            flow.record(true, for: page.id)
        }
    }
}

extension OnboardingFlowView where Welcome == EmptyView {
    /// A flow with no welcome page: goes straight to the steps.
    public init(
        flow: OnboardingFlow,
        onFinished: @escaping () -> Void = {},
        isAlreadySatisfied: @escaping (OnboardingStepConfig) -> Bool = { _ in false },
        @ViewBuilder stepContent: @escaping (OnboardingStepConfig, @escaping () -> Void) -> StepContent
    ) {
        self.flow = flow
        self.welcome = nil
        self.onFinished = onFinished
        self.isAlreadySatisfied = isAlreadySatisfied
        self.stepContent = stepContent
        flow.reconcile(isSatisfied: isAlreadySatisfied)
        let pages = OnboardingFlowPage.pending(in: flow, includeWelcome: false)
        _pages = State(initialValue: pages)
        _currentPageID = State(initialValue: pages.first?.id)
    }
}
