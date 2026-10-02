import SwiftUI

/// A step's icon, title, and optional explanatory headline. All optional
/// except the title, since not every step needs an icon (Marie's steps
/// don't use one) or a headline (a step whose content speaks for itself).
public struct OnboardingHeader {
    public var icon: String?
    public var title: LocalizedStringKey
    public var headline: LocalizedStringKey?

    public init(icon: String? = nil, title: LocalizedStringKey, headline: LocalizedStringKey? = nil) {
        self.icon = icon
        self.title = title
        self.headline = headline
    }
}
