import SwiftUI

/// The narrowest width that lays text out in the same number of lines as it
/// has at `maxWidth`. Wrapping text greedily leaves one long line and a stub
/// ("taken." alone); at the narrowest width that still fits the same line
/// count the lines come out even, which is what CSS `text-wrap: balance`
/// does. `measure` returns the text's height at a width and must not grow
/// as the width grows (greedy wrapping satisfies that).
enum BalancedWidth {
    static func narrowest(maxWidth: CGFloat, measure: (CGFloat) -> CGFloat) -> CGFloat {
        let fullHeight = measure(maxWidth)
        var low: CGFloat = 0
        var high = maxWidth
        while high - low > 1 {
            let mid = (low + high) / 2
            if measure(mid) <= fullHeight + 0.5 {
                high = mid
            } else {
                low = mid
            }
        }
        return high
    }
}

struct BalancedTextLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let text = subviews.first else { return .zero }
        // No finite width to balance against (an unconstrained measure).
        guard let maxWidth = proposal.width, maxWidth.isFinite, maxWidth > 0 else {
            return text.sizeThatFits(proposal)
        }
        let width = BalancedWidth.narrowest(maxWidth: maxWidth) {
            text.sizeThatFits(ProposedViewSize(width: $0, height: nil)).height
        }
        return text.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )
    }
}

public extension View {
    /// Wraps a multi-line `Text` so its lines come out even instead of
    /// leaving a one-word last line. Apply it to the text itself, after
    /// `multilineTextAlignment`, so the narrower block is centered by its
    /// parent and each line is centered inside it:
    ///
    ///     Text(message).multilineTextAlignment(.center).balancedText()
    ///
    /// The kit applies it to every step header's title and headline.
    func balancedText() -> some View {
        BalancedTextLayout { self }
    }
}
