# HowdyKit

Shared onboarding for CrumbDB, Marie, and future apps: one storage layer every
platform target uses the same way, and themeable step views for the platforms
that run a real multi-step flow.

## Storage layer

Pure Foundation, no SwiftUI, no platform-specific UI dependency. A watch
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
  - `needsOnboarding`: true while anything is unrecorded. The entire watchOS
    surface is this one property, no view, no step model needed there.
  - `nextStepNeeded`: the first unrecorded step, in declaration order.
  - `allRequiredSatisfied`: every required step answered `true` specifically,
    not just answered, declining a required step doesn't satisfy it.
  - `recordIfNeeded(leaving:isSkippable:)`: call when a step's view is being
    left (its own button, or a swipe past it in a paged container) and may
    still be unanswered. Writing nothing on a swipe-past would make the step
    look never-seen and show it again later; this backfills the step's
    default exactly once, `true` for a step with no skip path (there's only
    one way to leave it), `false` for a skippable one (leaving it unanswered
    is the same as tapping Skip). Never overwrites a real answer.

## View layer (`HowdyKitUI`, a separate product)

Separate from `HowdyKit` so a watchOS target depending only on the storage
layer never compiles SwiftUI it doesn't use.

- **`OnboardingTheme`**: primary color, card background (`ShapeStyle`, any
  material or color), fonts, and a custom background view, all defaulted to
  plain system styling. CrumbDB's brand (custom font, topo background) and
  Marie's plain look are the same view with different themes passed in, not
  different views.
- **`OnboardingHeader`**: icon (optional), title, headline (optional).
- **`OnboardingAction`**: a title and a handler, not a state machine.
  CrumbDB's primary button changes label as permission state changes (Allow
  Location → Open Settings → Next); that's the app's own logic recomputing
  which `OnboardingAction` to pass on each render, the view itself just
  renders whatever it's given right now.
- **`OnboardingStepView`**: header + arbitrary `@ViewBuilder` content +
  primary/optional-secondary actions, themed. Renders one step.
- **`OnboardingWelcomeView`**: the first-run screen. No header/content split
  forced on it (a hero layout usually wants more room than that), no skip,
  a single action that records `true` for its step ID itself. Still themed
  and still the same `OnboardingFlow` API as every other step, just its own
  config so the layout can be as custom as CrumbDB's brand intro or Marie's
  plain "Welcome to Marie" needs.
- **`OnboardingFlowView`**: sequences the steps a flow still needs into a
  paged container. An app hands it per-step content (keyed by
  `OnboardingStepConfig`) and an `advance` closure to call once that step's
  own action has recorded an answer; the container handles paging,
  swipe-past backfill (`flow.recordIfNeeded(leaving:isSkippable:)`, using
  `!step.isRequired` as the skippable default), and calls `onFinished` once
  the last step advances. This is the turnkey piece: CrumbDB and Marie get
  the same flow mechanics, not just the same per-step look.

All three are genuinely turnkey. An app can still build its own container
instead (a branching `NavigationStack`, a tvOS focus-driven push flow) when
`OnboardingFlowView`'s linear paging doesn't fit, but that's an escape hatch,
not the expected path.
