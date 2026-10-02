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
}
