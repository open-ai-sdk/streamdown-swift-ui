import Foundation
import SwiftUI

/// Parses inline markdown to AttributedString, with stream-aware
/// handling of incomplete markers.
public enum InlineParser {

    /// Parse inline markdown text to AttributedString.
    /// Handles incomplete markers gracefully during streaming.
    public static func parse(
        _ text: String,
        isStreaming: Bool = false
    ) -> AttributedString {
        // 1. Try system parser first
        if let result = try? AttributedString(markdown: text) {
            return result
        }

        // 2. If streaming, clean up incomplete markers and retry
        if isStreaming {
            let cleaned = cleanIncompleteMarkers(text)
            if let result = try? AttributedString(markdown: cleaned) {
                return result
            }
        }

        // 3. Fallback: plain text
        return AttributedString(text)
    }

    /// Remove trailing incomplete inline markers that break the parser.
    /// e.g., "hello **world" -> "hello world"
    /// e.g., "hello `code" -> "hello code"
    public static func cleanIncompleteMarkers(_ text: String) -> String {
        var result = text

        // Count ** occurrences — if odd, strip trailing unpaired **
        let doubleStarCount = countOccurrences(of: "**", in: result)
        if doubleStarCount % 2 != 0 {
            if let range = result.range(of: "**", options: .backwards) {
                result.removeSubrange(range)
            }
        }

        // Count backtick occurrences — if odd, strip trailing unpaired `
        let backtickCount = result.filter({ $0 == "`" }).count
        if backtickCount % 2 != 0 {
            if let lastIndex = result.lastIndex(of: "`") {
                result.remove(at: lastIndex)
            }
        }

        // Count single * (not part of **) — if odd, strip trailing unpaired *
        let singleStarCount = countSingleStars(in: result)
        if singleStarCount % 2 != 0 {
            if let lastIndex = result.lastIndex(of: "*") {
                result.remove(at: lastIndex)
            }
        }

        return result
    }

    // MARK: - Private Helpers

    private static func countOccurrences(of target: String, in text: String) -> Int {
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: target, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }

    private static func countSingleStars(in text: String) -> Int {
        var count = 0
        let chars = Array(text)
        for i in 0..<chars.count {
            if chars[i] == "*" {
                let prevIsStar = i > 0 && chars[i - 1] == "*"
                let nextIsStar = i + 1 < chars.count && chars[i + 1] == "*"
                if !prevIsStar && !nextIsStar {
                    count += 1
                }
            }
        }
        return count
    }
}
