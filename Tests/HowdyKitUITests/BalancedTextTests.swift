import CoreGraphics
import Testing
@testable import HowdyKitUI

@Suite("BalancedWidth")
struct BalancedTextTests {
    private let charWidth: CGFloat = 10
    private let lineHeight: CGFloat = 20

    /// Greedy word wrap with fixed-width characters, the same shape of
    /// problem a real text layout solves.
    private func lines(_ text: String, at width: CGFloat) -> [String] {
        let perLine = max(1, Int(width / charWidth))
        var result: [String] = []
        var current = ""
        for word in text.split(separator: " ") {
            let candidate = current.isEmpty ? String(word) : current + " " + word
            if candidate.count <= perLine || current.isEmpty {
                current = candidate
            } else {
                result.append(current)
                current = String(word)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private func measure(_ text: String) -> (CGFloat) -> CGFloat {
        { width in CGFloat(lines(text, at: width).count) * lineHeight }
    }

    private let sentence = "Dolly lines up your location history with each photo's timestamp and suggests where it was taken."

    /// At 49 characters per line the sentence wraps to three lines with
    /// "taken." alone on the last (at 50 it fits on two).
    private let orphanWidth: CGFloat = 490

    @Test("Keeps the line count the text has at full width")
    func keepsLineCount() {
        let full = lines(sentence, at: orphanWidth)
        let width = BalancedWidth.narrowest(maxWidth: orphanWidth, measure: measure(sentence))
        #expect(lines(sentence, at: width).count == full.count)
        #expect(width <= orphanWidth)
    }

    @Test("Pulls a one-word last line up into an even block")
    func fixesOrphan() throws {
        let greedy = lines(sentence, at: orphanWidth)
        #expect(greedy.count == 3)
        #expect(greedy.last == "taken.")

        let width = BalancedWidth.narrowest(maxWidth: orphanWidth, measure: measure(sentence))
        let balanced = lines(sentence, at: width)
        let last = try #require(balanced.last)
        #expect(last.split(separator: " ").count > 1)
        #expect(last.count * 2 >= (balanced.map(\.count).max() ?? 0))
    }

    @Test("A single line shrinks to its own width, no narrower")
    func singleLine() {
        let text = "Photo Library"
        let width = BalancedWidth.narrowest(maxWidth: 340, measure: measure(text))
        #expect(lines(text, at: width).count == 1)
        #expect(width >= CGFloat(text.count) * charWidth - 1)
        #expect(width < 340)
    }

    @Test("A width too small for any wrap change returns it unchanged")
    func tinyWidth() {
        let width = BalancedWidth.narrowest(maxWidth: 1, measure: measure(sentence))
        #expect(width == 1)
    }
}
