import { describe, expect, it } from "vitest";
import { APPS } from "../src/apps";
import { validateEventShape } from "../src/event-shape";

// Every event CrumbDB sends, as AnalyticsEvent.swift's `payload` builds it
// (dryan-org/crumbdb-app after PR #30), with the real values each string field can
// take at its call sites. CrumbDB has no identifying keys, so each must pass
// the shared shape check with an empty set. A payload of null is a known
// client-side shape problem, listed with a TODO and pinned by the test below.
const CRUMBDB_EVENTS: Record<string, (Record<string, unknown> | null)[]> = {
  appLaunch: [
    { event_type: "appLaunch", is_new_install: true },
    { event_type: "appLaunch", is_new_install: false },
  ],
  // SessionDuration.analyticsToken
  sessionStarted: ["30m", "1h", "2h", "4h", "until_stopped"].map((d) => ({ event_type: "sessionStarted", duration_chosen: d, live_activity_shown: d === "1h" })),
  sessionEnded: [
    { event_type: "sessionEnded", duration_chosen: "30m", actual_duration_seconds: 1800, end_reason: "scheduled" },
    { event_type: "sessionEnded", duration_chosen: "until_stopped", actual_duration_seconds: 3247, end_reason: "manual" },
  ],
  sessionRestored: [{ event_type: "sessionRestored" }],
  sessionExtended: [
    { event_type: "sessionExtended", minutes_added: 30 },
    { event_type: "sessionExtended", minutes_added: 0 },
  ],
  photoMatchCompleted: [
    {
      event_type: "photoMatchCompleted", library_size: 5000, unmatched_count: 57, matched_count: 47, dismissed_count: 3, duration_ms: 1842,
      interpolated_count: 4, snapped_count: 2, median_delta_seconds: 20,
    },
    { event_type: "photoMatchCompleted", library_size: 0, unmatched_count: 0, matched_count: 0, dismissed_count: 0, duration_ms: 12, interpolated_count: 0, snapped_count: 0 },
  ],
  // LocationSource.matchSourceTag, plus "tagged_photo" and "manual" (PhotoMergeService.swift)
  photoApplied: ["background_location", "live_session", "healthkit", "gpx_import", "tagged_photo", "manual"].map((s) => ({ event_type: "photoApplied", match_source: s })),
  photoDismissed: [
    { event_type: "photoDismissed", had_match: true },
    { event_type: "photoDismissed", had_match: false },
  ],
  photoAdjusted: [
    { event_type: "photoAdjusted", had_match: true, used_search: false, meters_from_match: 120 },
    { event_type: "photoAdjusted", had_match: false, used_search: true },
  ],
  workoutSynced: [{ event_type: "workoutSynced", workout_count: 3 }],
  // GPXImportEntryPoint raw values
  gpxImportStarted: ["file_picker", "open_in"].map((e) => ({ event_type: "gpxImportStarted", prior_imports: 0, entry_point: e })),
  gpxImported: [{ event_type: "gpxImported", tracks: 2, points: 200, raw_points: 1000, duration_minutes: 200, prior_imports: 3 }],
  // GPXImportError.analyticsReason, and GPXErrorDetail / GPXParseDiagnostic.redacted forms
  gpxImportFailed: [
    { event_type: "gpxImportFailed", reason: "notGPX", prior_imports: 0 },
    { event_type: "gpxImportFailed", reason: "noTimestamps", prior_imports: 1 },
    { event_type: "gpxImportFailed", reason: "readError", detail: "cocoa_code_260", prior_imports: 0 },
    { event_type: "gpxImportFailed", reason: "parseError", detail: "xml_code_5_line_12_col_40", prior_imports: 2 },
    { event_type: "gpxImportFailed", reason: "storeError", detail: "store_code_517", prior_imports: 0 },
    { event_type: "gpxImportFailed", reason: "storeError", detail: "store_type_SomeErrorType", prior_imports: 0 },
  ],
  backgroundScan: ["scheduled", "location"].map((s) => ({ event_type: "backgroundScan", source: s, new_matches: 4 })),
  proPurchased: [{ event_type: "proPurchased" }],
  // .paywall(trigger:) call sites
  paywallShown: ["threshold", "apply_gated"].map((t) => ({ event_type: "paywallShown", trigger: t })),
  // AnalyticsErrorContext: .word -> context; .code -> error_domain (AnalyticsToken) + error_code
  error: [
    { event_type: "error", type: "storekit_products", context: "empty" },
    { event_type: "error", type: "storekit_products", error_domain: "NSCocoaErrorDomain", error_code: 3072 },
    { event_type: "error", type: "storekit_products", error_domain: "StoreKit_StoreKitError", error_code: 2 },
    { event_type: "error", type: "storekit_products", error_domain: "crumbdb_Foo_Bar", error_code: -1 },
    { event_type: "error", type: "storekit_products", error_code: 0 },
  ],
  // String(describing: OnboardingView.Page)
  onboardingPage: ["intro", "photos", "health", "location", "iphone", "notifications"].map((p) => ({ event_type: "onboardingPage", page: p })),
  // PermissionKind raw values; results from CLAuthorizationStatus / PHAuthorizationStatus analyticsName, or granted/denied
  permissionAnswered: [
    ...["always", "when_in_use", "denied", "restricted", "not_determined", "unknown"].map((r) => ({ event_type: "permissionAnswered", kind: "location", result: r })),
    ...["full", "limited", "denied", "restricted", "not_determined", "unknown"].map((r) => ({ event_type: "permissionAnswered", kind: "photos", result: r })),
    { event_type: "permissionAnswered", kind: "health", result: "granted" },
    { event_type: "permissionAnswered", kind: "notifications", result: "denied" },
  ],
  onboardingFinished: [{ event_type: "onboardingFinished", all_granted: true }],
  paywallDismissed: [{ event_type: "paywallDismissed", trigger: "apply_gated", seconds_shown: 14 }],
  purchaseStarted: [{ event_type: "purchaseStarted", trigger: "threshold" }],
  purchaseFailed: [
    { event_type: "purchaseFailed", reason: "cancelled_or_pending" },
    // TODO: purchaseFailed.reason still fails shape validation, needs a follow-up crumbdb fix (PaywallView.swift sends the raw
    // `(error as NSError).domain` of a thrown error, e.g. "StoreKit.StoreKitError" or "crumbdb.StoreError", which HOSTNAME_LIKE rejects)
    null,
  ],
  restoreAttempted: ["restored", "nothing"].map((r) => ({ event_type: "restoreAttempted", result: r })),
  lockedApplyTapped: [{ event_type: "lockedApplyTapped" }],
  thresholdChanged: [{ event_type: "thresholdChanged", from: 300, to: 900 }],
  photoOpened: [{ event_type: "photoOpened", from: "list" }],
  applyFailed: [
    // TODO: applyFailed.error still fails shape validation, needs a follow-up crumbdb fix (PhotoMergeService.swift and PhotosView.swift
    // send "\(nsError.domain) \(nsError.code)", e.g. "PHPhotosErrorDomain 3300": the space fails TOKEN on every applyFailed event)
    null,
  ],
  sourcesAtLaunch: [
    { event_type: "sourcesAtLaunch", location: "always", health: "requested", photos: "full" },
    { event_type: "sourcesAtLaunch", location: "when_in_use", health: "not_requested", photos: "limited" },
    { event_type: "sourcesAtLaunch", location: "not_determined", health: "unavailable", photos: "not_determined" },
  ],
  // StoreOutcome and LaunchDestination raw values
  launchCompleted: [
    ...["cloudReady", "localFallback", "localFallbackTimeout", "localOnly"].map((o) => ({ event_type: "launchCompleted", duration_ms: 1250, outcome: o, destination: "mainContent" })),
    { event_type: "launchCompleted", duration_ms: 900, outcome: "localOnly", destination: "onboarding" },
  ],
  syncState: ["cloud", "local"].map((s) => ({ event_type: "syncState", state: s })),
  photoKeys: [{ event_type: "photoKeys", resolved: 812, unresolved: 3 }],
  scanScheduleFailed: [{ event_type: "scanScheduleFailed" }],
  bulkApplied: [{ event_type: "bulkApplied", count: 40, failed: 1, cancelled: false }],
  bulkDismissed: [{ event_type: "bulkDismissed", count: 12, matched_count: 5 }],
  dismissUndone: [{ event_type: "dismissUndone", count: 40 }],
  applyUndone: [{ event_type: "applyUndone", count: 12, failed: 0 }],
  // CrashReporter: kind exception|signal; name the NSException name or signal name; top_frame through AnalyticsToken
  crashDetected: [
    { event_type: "crashDetected", kind: "exception", name: "NSInvalidArgumentException", top_frame: "s7crumdb11LocationSvcC5startyyF" },
    { event_type: "crashDetected", kind: "exception", name: "NSRangeException", top_frame: "exceptionPreprocess" },
    ...["SIGABRT", "SIGILL", "SIGSEGV", "SIGFPE", "SIGBUS", "SIGTRAP", "SIGNAL"].map((n) => ({ event_type: "crashDetected", kind: "signal", name: n })),
  ],
};

/** The payloads behind the TODOs above, as the current client sends them. */
const KNOWN_CLIENT_FAILURES: Record<string, unknown>[] = [
  { event_type: "purchaseFailed", reason: "StoreKit.StoreKitError" },
  { event_type: "purchaseFailed", reason: "StoreKit.Product.PurchaseError" },
  { event_type: "purchaseFailed", reason: "crumbdb.StoreError" },
  { event_type: "applyFailed", error: "PHPhotosErrorDomain 3300" },
  { event_type: "applyFailed", error: "NSCocoaErrorDomain -1" },
];

describe("every CrumbDB event passes the shared shape check", () => {
  it("covers all 38 AnalyticsEvent cases", () => {
    expect(Object.keys(CRUMBDB_EVENTS)).toHaveLength(38);
    for (const [name, payloads] of Object.entries(CRUMBDB_EVENTS)) {
      for (const payload of payloads) if (payload) expect(payload.event_type, name).toBe(name);
    }
  });

  for (const [name, payloads] of Object.entries(CRUMBDB_EVENTS)) {
    it(name, () => {
      for (const payload of payloads) {
        if (!payload) continue;
        expect(validateEventShape(payload, new Set()), JSON.stringify(payload)).toBeNull();
        expect(APPS.crumbdb.validateEvent(payload), JSON.stringify(payload)).toBeNull();
      }
    });
  }

  it("still refuses the two fields a crumbdb follow-up must fix (see the TODOs)", () => {
    for (const payload of KNOWN_CLIENT_FAILURES) {
      expect(APPS.crumbdb.validateEvent(payload), JSON.stringify(payload)).toMatch(/must be a short token/);
    }
  });
});
