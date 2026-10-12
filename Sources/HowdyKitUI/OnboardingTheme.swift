import SwiftUI

/// Visual identity for a flow: colors, fonts, and an optional custom
/// background, injected by each app rather than hardcoded. The same step
/// view renders one app's brand (custom font, custom background, card chrome)
/// and another's plain system look without forking the view itself, only the
/// theme in the environment differs.
///
/// Views read it from the environment. Set it once at the app's root with
/// `.onboardingTheme(_:)` and every `HowdyKitUI` view below picks it up, no
/// per-view plumbing.
///
/// Not `Sendable`: this is SwiftUI configuration data, read on the main
/// actor as part of rendering, the same as the views it configures.
public struct OnboardingTheme {
    /// Text color (titles). See `accentColor` for the interactive highlights.
    public var primaryColor: Color
    /// Interactive and brand highlights: the header icon, the primary button,
    /// the Skip text, the current page dot. Primary is for text. Defaults to
    /// `primaryColor` when not given.
    public var accentColor: Color
    /// When set, each step's header and content are drawn inside a rounded
    /// card filled with it; `nil` means no card. Pass one as
    /// `AnyShapeStyle(.regularMaterial)` or `AnyShapeStyle(Color.x.opacity(0.85))`.
    public var cardBackground: AnyShapeStyle?
    public var titleFont: Font
    public var headlineFont: Font
    public var bodyFont: Font
    public var background: AnyView
    /// Space between the primary and the secondary footer action, in points.
    /// Stacked buttons need at least 24 pt so a tap on one never lands on the
    /// other.
    public var footerActionSpacing: CGFloat
    /// Text color of the primary (prominent) button. `nil` picks white or
    /// black from the accent's luminance; see `primaryButtonTextColor(in:)`.
    public var primaryButtonTextColor: Color?

    public init(
        primaryColor: Color = .primary,
        accentColor: Color? = nil,
        cardBackground: AnyShapeStyle? = nil,
        titleFont: Font = .title2.bold(),
        headlineFont: Font = .headline,
        bodyFont: Font = .subheadline,
        footerActionSpacing: CGFloat = OnboardingTheme.defaultFooterActionSpacing,
        primaryButtonTextColor: Color? = nil,
        @ViewBuilder background: () -> some View = { Color.clear }
    ) {
        self.primaryColor = primaryColor
        self.accentColor = accentColor ?? primaryColor
        self.cardBackground = cardBackground
        self.titleFont = titleFont
        self.headlineFont = headlineFont
        self.bodyFont = bodyFont
        self.background = AnyView(background())
        self.footerActionSpacing = footerActionSpacing
        self.primaryButtonTextColor = primaryButtonTextColor
    }

    /// The default gap between stacked footer actions.
    public static let defaultFooterActionSpacing: CGFloat = 24
    /// The smallest height of a footer action, the platform's minimum target.
    public static let minimumActionHeight: CGFloat = 44

    /// The primary button's text color: the theme's override, else white on a
    /// dark accent and black on a light one.
    public func primaryButtonTextColor(in environment: EnvironmentValues) -> Color {
        primaryButtonTextColor ?? Self.contrastingTextColor(on: accentColor, in: environment)
    }

    /// White on dark colors, black on light ones, by relative luminance
    /// (WCAG weights on linear components). 0.179 is where white and black
    /// text have equal contrast.
    public static func contrastingTextColor(on background: Color, in environment: EnvironmentValues) -> Color {
        relativeLuminance(of: background, in: environment) > 0.179 ? .black : .white
    }

    /// WCAG relative luminance, 0 (black) to 1 (white), of a color resolved
    /// in `environment` (so dynamic colors follow its color scheme).
    public static func relativeLuminance(of color: Color, in environment: EnvironmentValues) -> Double {
        let c = color.resolve(in: environment)
        return 0.2126 * Double(max(0, min(1, c.linearRed)))
            + 0.7152 * Double(max(0, min(1, c.linearGreen)))
            + 0.0722 * Double(max(0, min(1, c.linearBlue)))
    }

    /// Plain system styling: no custom font, no custom background, no
    /// card. What an app reaches for until it wants to
    /// brand the flow.
    public static let `default` = OnboardingTheme()
}

public extension EnvironmentValues {
    @Entry var onboardingTheme: OnboardingTheme = .default
}

public extension View {
    /// Sets the theme every HowdyKitUI view below this point renders with.
    func onboardingTheme(_ theme: OnboardingTheme) -> some View {
        environment(\.onboardingTheme, theme)
    }
}
