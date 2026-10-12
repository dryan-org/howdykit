import SwiftUI
import Testing

@testable import HowdyKitUI

@MainActor
@Suite("OnboardingTheme environment")
struct OnboardingThemeTests {
    @Test func environmentDefaultsToDefaultTheme() {
        let theme = EnvironmentValues().onboardingTheme
        #expect(theme.primaryColor == Color.primary)
        #expect(theme.titleFont == Font.title2.bold())
    }

    @Test func customThemeRoundTripsThroughEnvironment() {
        var env = EnvironmentValues()
        env.onboardingTheme = OnboardingTheme(primaryColor: .red)
        #expect(env.onboardingTheme.primaryColor == .red)
    }

    @Test func noArgumentInitMatchesDefault() {
        let theme = OnboardingTheme()
        #expect(theme.primaryColor == OnboardingTheme.default.primaryColor)
        #expect(theme.titleFont == OnboardingTheme.default.titleFont)
        #expect(theme.headlineFont == OnboardingTheme.default.headlineFont)
        #expect(theme.bodyFont == OnboardingTheme.default.bodyFont)
    }

    @Test func accentDefaultsToPrimary() {
        #expect(OnboardingTheme(primaryColor: .red).accentColor == .red)
        #expect(OnboardingTheme().accentColor == Color.primary)
    }

    @Test func explicitAccentIsKept() {
        let theme = OnboardingTheme(primaryColor: .red, accentColor: .orange)
        #expect(theme.primaryColor == .red)
        #expect(theme.accentColor == .orange)
    }

    @Test func cardBackgroundIsNilByDefaultAndSetWhenGiven() {
        #expect(OnboardingTheme().cardBackground == nil)
        #expect(OnboardingTheme.default.cardBackground == nil)
        #expect(OnboardingTheme(cardBackground: AnyShapeStyle(.regularMaterial)).cardBackground != nil)
        #expect(OnboardingTheme(cardBackground: AnyShapeStyle(Color.white.opacity(0.85))).cardBackground != nil)
    }
}

@MainActor
@Suite("OnboardingTheme footer layout and button contrast")
struct OnboardingThemeLayoutTests {
    private let env = EnvironmentValues()

    @Test func footerSpacingDefaultsToAtLeast24() {
        #expect(OnboardingTheme().footerActionSpacing == 24)
        #expect(OnboardingTheme.default.footerActionSpacing >= 24)
        #expect(OnboardingTheme(footerActionSpacing: 32).footerActionSpacing == 32)
    }

    @Test func minimumActionHeightIs44() {
        #expect(OnboardingTheme.minimumActionHeight == 44)
    }

    @Test func darkAccentGetsWhiteText() {
        for accent in [Color.black, Color(red: 0.1, green: 0.2, blue: 0.5), Color(red: 0.5, green: 0.1, blue: 0.1)] {
            #expect(OnboardingTheme(accentColor: accent).primaryButtonTextColor(in: env) == .white)
        }
    }

    @Test func lightAccentGetsBlackText() {
        for accent in [Color.white, Color.yellow, Color(red: 0.6, green: 1, blue: 0.8)] {
            #expect(OnboardingTheme(accentColor: accent).primaryButtonTextColor(in: env) == .black)
        }
    }

    @Test func luminanceOrdersBlackBelowWhite() {
        #expect(OnboardingTheme.relativeLuminance(of: .black, in: env) < 0.01)
        #expect(OnboardingTheme.relativeLuminance(of: .white, in: env) > 0.99)
    }

    @Test func themeOverrideWinsOverLuminance() {
        let theme = OnboardingTheme(accentColor: .yellow, primaryButtonTextColor: .purple)
        #expect(theme.primaryButtonTextColor(in: env) == .purple)
    }

    @Test func headerIconSizeScalesFromSemanticBase() {
        #expect(OnboardingLayout.headerIconSize == 64)
        #expect(OnboardingLayout.footerIsPinned)
    }
}
