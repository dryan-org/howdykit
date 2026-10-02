import SwiftUI

/// One button. Deliberately just a title and a handler, not a state machine:
/// A permission step's primary button changes label as its state changes
/// (Allow Location → Open Settings → Next), but that's permission-specific
/// logic the app already owns. The app recomputes which `OnboardingAction`
/// to hand the view on each render; the view itself only ever renders
/// whatever it's given right now.
public struct OnboardingAction {
    public var title: LocalizedStringKey
    public var isProminent: Bool
    public var handler: () -> Void

    public init(title: LocalizedStringKey, isProminent: Bool = true, handler: @escaping () -> Void) {
        self.title = title
        self.isProminent = isProminent
        self.handler = handler
    }
}
