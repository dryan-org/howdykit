# HowdyKit

Shared onboarding for CrumbDB, Marie, and future apps: one storage layer every
platform target uses the same way, and (coming next) themeable step views for
the platforms that run a real multi-step flow.

## Storage layer (this package, today)

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

## Not yet built

The view layer: a themeable step view (header/content/actions) and a
welcome-style config for the one no-skip, custom-view, first-run-only screen
that isn't a `reqs.*` step at all. Each app composes its own container around
these (CrumbDB's swipeable pages, Marie's branching `NavigationStack`, a
future tvOS focus-driven push flow), the kit doesn't own sequencing.
