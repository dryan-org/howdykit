# HowdyKit

Shared onboarding for CrumbDB, Marie, and future apps: one storage layer every
platform target uses the same way, and themeable step views for the platforms
that run a real multi-step flow.

## Storage layer

Foundation and Observation only, no SwiftUI, no platform-specific UI dependency. A watch
target that only needs "is setup done" can depend on just this.

- **`OnboardingStepID`**: identifies one step across app versions. Reverse-DNS
  by convention (`com.dryan.crumbdb.reqs.health`) so records never collide
  across apps, and a step added later is just a new, unrecognized ID.
  Required-ness is not part of the ID, it lives on `OnboardingStepConfig`
  instead, so flipping a step between required and optional later never
  orphans existing records.
- **`OnboardingStorage`**: reads/writes one step's tri-state record, `nil`
  (never recorded), `true` (granted/completed/acknowledged), or `false`
  (declined/skipped). `nil` is the whole mechanism behind adding a step a
  year later: a returning user has real records for every step that existed
  when they onboarded, and `nil` for the new one.
- **`UserDefaultsOnboardingStorage`**: the default implementation, one suite,
  one key per step (prefixed, so one suite can hold more than one app's or
  flow's records). Shares naturally with same-device extensions/widgets via
  an App Group suite. Does **not** reach a paired Watch on its own, that's a
  separate device with its own sandbox; bridge it with
  `NSUbiquitousKeyValueStore` or `WatchConnectivity` instead, not App Groups.
- **`OnboardingFlow`**: ties a step list to storage.
  - `welcomeID` / `needsWelcome`: an optional welcome ID the flow tracks but
    does not page (it isn't one of `steps`). `needsWelcome` is true while that
    ID is unrecorded, and always false for a flow created without `welcome:`.
    `reset()` clears it along with the steps.
  - `needsOnboarding`: true while the welcome or any step is unrecorded. The entire watchOS
    surface is this one property, no view, no step model needed there.
  - `nextStepNeeded`: the first unrecorded step, in declaration order.
  - `allRequiredSatisfied`: every required step answered `true` specifically,
    not just answered, declining a required step doesn't satisfy it.
  - `recordIfNeeded(leaving:)`: call with the step's `OnboardingStepConfig`
    when its view is being left (its own button, or a swipe past it in a
    paged container) and may still be unanswered. Writing nothing on a
    swipe-past would make the step look never-seen and show it again later;
    this backfills the step's default exactly once, reading
    `step.isSkippable`: `false` for a skippable step (leaving it unanswered
    is the same as tapping Skip), `true` for a non-skippable,
    acknowledge-only step (there's only one way to leave it). Never
    overwrites a real answer.
  - `reconcile(isSatisfied:)`: records `true` for every unanswered step the
    closure reports as already satisfied outside the flow (a permission the OS
    already granted). Leaves answered steps alone and only notifies
    observers when it records something.
- **`OnboardingStepConfig`**: a step's `id` plus two independent flags.
  `isRequired`: the flow isn't satisfied until the step is recorded `true`.
  `isSkippable` (default `true`): the step can be left unanswered, which
  counts as declining. So swiping past a required permission step records
  `false` and `allRequiredSatisfied` stays `false`; it never counts as
  granted. A non-skippable step is acknowledge-only (an info screen) and
  is normally not required.

## View layer (`HowdyKitUI`, a separate product)

Separate from `HowdyKit` so a watchOS target depending only on the storage
layer never compiles SwiftUI it doesn't use.

- **`OnboardingTheme`**: primary color (text) and accent color (header icon, buttons, Skip, page dot; defaults to primary), optional card background (`AnyShapeStyle`, any
  material or color; nil means no card), fonts, and a custom background view, all defaulted to
  plain system styling. Provided through the environment with
  `.onboardingTheme(_:)` at the root. CrumbDB's brand (custom font, topo
  background) and Marie's plain look are the same view with different themes,
  not different views.
- **`OnboardingHeader`**: icon (optional), title, headline (optional).
- **`OnboardingAction`**: a title and a handler, not a state machine.
  CrumbDB's primary button changes label as permission state changes (Allow
  Location → Open Settings → Next); that's the app's own logic recomputing
  which `OnboardingAction` to pass on each render, the view itself just
  renders whatever it's given right now.
- **`OnboardingStepView`**: header + arbitrary `@ViewBuilder` content +
  primary/optional-secondary actions, themed, drawn inside a rounded card when the theme sets `cardBackground`. Renders one step. Inside a flow
  it publishes its actions to `OnboardingFlowView`'s shared footer; on its own
  it draws the footer itself.
- **`OnboardingWelcomeView`**: the first-run screen. No header/content split
  forced on it (a hero layout usually wants more room than that), no skip,
  a single action that records `true` for the flow's `welcomeID` itself.
  Still themed and still the same `OnboardingFlow` API as every other step,
  just its own config so the layout can be as custom as CrumbDB's brand intro or Marie's
  plain "Welcome to Marie" needs. Publishes its action to the flow's shared
  footer the same way a step does.
- **`OnboardingFlowView`**: shows the welcome first when the flow still needs
  it, then sequences the steps a flow still needs into a paged container.
  The pager is a paging `ScrollView` with the kit's own page dots, and one footer under it for
  whichever page is showing.
  Recording the welcome moves it on to the steps on its own, so an app
  doesn't branch on `needsWelcome` itself. An app hands it per-step content (keyed by
  `OnboardingStepConfig`) and an `advance` closure to call once that step's
  own action has recorded an answer; the container handles paging,
  swipe-past backfill (`flow.recordIfNeeded(leaving: step)`, driven by
  `step.isSkippable`; swiping past a required step is allowed and records
  `false`), and calls `onFinished` once
  the last step advances and `onPageShown` with the step ID each time a page is shown (for analytics). Pass `isAlreadySatisfied:` (for example, "is the
  OS permission already granted") and steps it accepts are recorded `true`
  through `flow.reconcile` before paging, and again when the app becomes
  active, so they never get a page. This is the turnkey piece: CrumbDB and Marie get
  the same flow mechanics, not just the same per-step look.

All three are genuinely turnkey. An app can still build its own container
instead (a branching `NavigationStack`, a tvOS focus-driven push flow) when
`OnboardingFlowView`'s linear paging doesn't fit, but that's an escape hatch,
not the expected path.
