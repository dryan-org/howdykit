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
