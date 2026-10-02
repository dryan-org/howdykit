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
  primary/optional-secondary actions, themed. This is the whole per-step
  template.

Not part of this: a welcome screen type (it's meant to be a unique view per
app, not templated, see below) or any container that sequences multiple
steps. Each app composes its own (CrumbDB's swipeable pages, Marie's
branching `NavigationStack`, a future tvOS focus-driven push flow) around
`OnboardingStepView` and `OnboardingFlow`; the kit doesn't own sequencing.

A swipeable container specifically needs to call
`flow.recordIfNeeded(leaving:isSkippable:)` from its page-change handler, not
just from each step's own button, so a swipe past an unanswered step doesn't
leave it looking never-seen.

## Welcome

Deliberately not a `HowdyKitUI` type. It's one no-skip, first-run-only screen
per app, and every app's version of it is different enough (CrumbDB's brand
intro vs. Marie's plain "Welcome to Marie") that templating it would fight
the one place where a truly custom view is the right call. Build it as a
normal view, give it a single "Continue" action, and call
`flow.record(true, for:)` directly, there's no second storage mechanism for
it, it's the same `OnboardingFlow` API as every other step.
