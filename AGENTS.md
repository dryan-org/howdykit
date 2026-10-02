# Integrating HowdyKit (for agents)

HowdyKit is the shared onboarding for dryan-org's apps (CrumbDB, Marie, and
whatever comes next). Integrate it; do not fork its views or reimplement the
flow in the app. `README.md` is the API reference; this file is the order of
operations and the rules that are easy to get wrong.

## 1. Dependency

Swift package, two products. Depend on a tag, not `main`.

XcodeGen (`project.yml`):

```yaml
packages:
  HowdyKit:
    url: https://github.com/dryan-org/howdykit
    from: "1.0.0"
targets:
  <App>:
    dependencies:
      - package: HowdyKit
        product: HowdyKit      # storage + flow model, Foundation and Observation only
      - package: HowdyKit
        product: HowdyKitUI    # SwiftUI views; iOS/macOS/tvOS targets only
```

A watchOS or widget target that only needs "is onboarding done" links
`HowdyKit` alone and asks `flow.needsOnboarding`.

Platform floor is 27 across the board.

## 2. Define the flow once, app-wide

One `OnboardingFlow` per app, created once and shared (a plain `final class`
holding it is fine; the flow itself is `@Observable`).

```swift
import HowdyKit

enum Onboarding {
    static let welcome  = OnboardingStepID("com.dryan.<app>.welcome")
    static let location = OnboardingStepID("com.dryan.<app>.reqs.location")
    static let photos   = OnboardingStepID("com.dryan.<app>.reqs.photos")
    static let tips     = OnboardingStepID("com.dryan.<app>.info.tips")
}

let flow = OnboardingFlow(
    welcome: Onboarding.welcome,
    steps: [
        OnboardingStepConfig(id: Onboarding.location, isRequired: true,  isSkippable: true),
        OnboardingStepConfig(id: Onboarding.photos,   isRequired: true,  isSkippable: true),
        OnboardingStepConfig(id: Onboarding.tips,     isRequired: false, isSkippable: false),
    ],
    storage: UserDefaultsOnboardingStorage(keyPrefix: "<app>.")
)
```

Rules:
- IDs are reverse-DNS and permanent. Never rename one; records are keyed by it.
  A new step is a new ID appended to `steps`; returning users see only it.
- `isRequired` and `isSkippable` are independent. Required means the flow is
  not satisfied until the step records `true`. Skippable means the step has a
  Skip path (button or swipe past), and leaving it unanswered records `false`.
  A step with no Skip (an info screen) records `true` when left. A required
  permission step is normally skippable too: the user may decline and the app
  stays unsatisfied; that is correct, do not record `true` for a denial.
- `keyPrefix` keeps one `UserDefaults` suite safe for more than one flow. Use
  an App Group suite only when an extension must read the records on the same
  device; it does not reach a paired Watch (use `NSUbiquitousKeyValueStore`
  or `WatchConnectivity` for that).

## 3. Decide "onboarding or app" from the flow, nowhere else

```swift
if flow.needsOnboarding { OnboardingRoot() } else { MainApp() }
```

Full-screen root swap, not a sheet. Do not keep a separate
`hasCompletedOnboarding` flag: `needsOnboarding` is the one source of truth
and it is observable, so the swap happens on its own when the last step is
recorded. If the app already has such a flag, migrate it once at launch
(flag set and every step unrecorded: record each step `true`) and delete it.

## 4. Build the screens with the kit's views

```swift
import HowdyKitUI

OnboardingFlowView(
    flow: flow,
    onFinished: { /* analytics, then nothing: needsOnboarding already flipped */ },
    isAlreadySatisfied: alreadyGranted,
    welcome: {
        OnboardingWelcomeView(flow: flow) { /* hero content */ }
    },
    stepContent: { step, advance in
        switch step.id {
        case Onboarding.location: LocationStep(flow: flow, stepID: step.id, advance: advance)
        case Onboarding.photos:   PhotosStep(flow: flow, stepID: step.id, advance: advance)
        case Onboarding.tips:     InfoStep(flow: flow, stepID: step.id, advance: advance)
        default: EmptyView()
        }
    }
)
.onboardingTheme(OnboardingTheme(primaryColor: brandColor, titleFont: brandFont, background: { Brand() }))
```

Each step is an `OnboardingStepView(header:primaryAction:secondaryAction:content:)`.
The step owns its state (permission status) and its actions; the kit renders
the buttons once, below the pages, with the dots above them, and sequences
the pages. The step's primary action must `flow.record(...)` then call
`advance()`; Skip records `false` then `advance()`.

Theme comes from the environment (`.onboardingTheme(_:)`), set once at the
root. Never pass a theme into a view; never hard-code brand colors in a step.

## 5. Reconcile system permissions

A permission the OS has already granted must not get a page. Pass
`isAlreadySatisfied:` and the kit records such steps `true` before paging and
again when the scene becomes active (Settings may have changed something):

```swift
func alreadyGranted(_ step: OnboardingStepConfig) -> Bool {
    switch step.id {
    case Onboarding.location:
        let s = CLLocationManager().authorizationStatus
        return s == .authorizedAlways || s == .authorizedWhenInUse
    case Onboarding.photos:
        let s = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return s == .authorized || s == .limited
    default: return false
    }
}
```

Permission steps that can be granted asynchronously (Core Location's
delegate) should also auto-advance on grant: watch the status and call
`flow.record(true, ...)` then `advance()` from `onChange`.

iOS never re-prompts for a permission once answered, and it shows the
While Using to Always upgrade prompt once per install. After that the only
path is Settings; make the button say "Open Settings" in that state rather
than calling the request again.

## 6. Analytics and replay are the app's

The kit fires no analytics. Fire the app's own events from the step actions
and from `onFinished`. For a "replay onboarding" entry in Settings, call
`flow.reset()`; for a dev screen that sets up one scenario, `flow.clear(id)`
and `flow.record(_:for:)` per step.

## Do not

- Snapshot `flow` queries into local `@State` to drive navigation. The flow
  is `@Observable`; read it in `body`.
- Put the welcome in `steps`. It is `welcome:` on the flow; the kit pages it
  first and records it.
- Build a parallel `TabView` or `NavigationStack` around `OnboardingStepView`
  for a linear flow. `OnboardingFlowView` is the pager; only a genuinely
  branching flow gets its own container.
- Use `#if DEBUG` for a reset button. Put it behind the app's beta flag.

## Verifying on a simulator without tapping

A `-autoAdvance` launch-argument hook (see Dolly's `AutoAdvance.swift` in the
dryan-org demo app) lets each step fire its primary path when it becomes the
flow's next unanswered step, so `xcrun simctl io <device> recordVideo` can
capture the whole flow. The recorder only writes frames while the screen
changes, so a short video means the flow finished early or got stuck. Reset
the app's records with uninstall + install; `simctl spawn ... defaults delete`
does not clear what the running app has cached.
