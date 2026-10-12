import CoreGraphics

/// Layout constants and rules the views share, kept apart from the views so
/// tests can assert them without a host.
enum OnboardingLayout {
    /// Header icon size at the default Dynamic Type size; the views scale it
    /// with `ScaledMetric(relativeTo: .largeTitle)`.
    static let headerIconSize: CGFloat = 64

    /// The footer is fixed, never part of the scrolling pages: dots and
    /// footer are laid out below the pager, which takes what is left and
    /// clips to it.
    static let footerIsPinned = true
}
