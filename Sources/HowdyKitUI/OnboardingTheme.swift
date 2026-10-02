import SwiftUI

/// Visual identity for a flow: colors, fonts, and an optional custom
/// background, injected by each app rather than hardcoded. The same step
/// view renders CrumbDB's brand (custom font, topo background, card chrome)
/// and Marie's plain system look without forking the view itself, only the
/// theme in the environment differs.
///
/// Views read it from the environment. Set it once at the app's root with
/// `.onboardingTheme(_:)` and every `HowdyKitUI` view below picks it up, no
/// per-view plumbing.
///
/// Not `Sendable`: this is SwiftUI configuration data, read on the main
/// actor as part of rendering, the same as the views it configures.
public struct OnboardingTheme {
    public var primaryColor: Color
    public var cardBackground: AnyShapeStyle
    public var titleFont: Font
    public var headlineFont: Font
    public var bodyFont: Font
    public var background: AnyView

    public init(
        primaryColor: Color = .primary,
        cardBackground: some ShapeStyle = .regularMaterial,
        titleFont: Font = .title2.bold(),
        headlineFont: Font = .headline,
        bodyFont: Font = .subheadline,
        @ViewBuilder background: () -> some View = { Color.clear }
    ) {
        self.primaryColor = primaryColor
        self.cardBackground = AnyShapeStyle(cardBackground)
        self.titleFont = titleFont
        self.headlineFont = headlineFont
        self.bodyFont = bodyFont
        self.background = AnyView(background())
    }

    /// Plain system styling: no custom font, no custom background, a
    /// materials-based card. What an app reaches for until it wants to
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
