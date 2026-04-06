import Testing
@testable import StreamdownSwiftUI

@Suite("Inline Parser")
struct InlineParserTests {

    @Test("Parses plain text to AttributedString")
    func plainText() {
        let result = InlineParser.parse("hello world")
        #expect(String(result.characters) == "hello world")
    }

    @Test("Parses bold text")
    func bold() {
        let result = InlineParser.parse("**bold text**")
        // System AttributedString(markdown:) should produce a non-empty result
        #expect(!result.characters.isEmpty)
    }

    @Test("Parses inline code")
    func inlineCode() {
        let result = InlineParser.parse("`code`")
        #expect(!result.characters.isEmpty)
    }

    @Test("Cleans incomplete bold marker during streaming")
    func incompleteBold() {
        let cleaned = InlineParser.cleanIncompleteMarkers("hello **world")
        #expect(!cleaned.contains("**"))
    }

    @Test("Cleans incomplete inline code during streaming")
    func incompleteCode() {
        let cleaned = InlineParser.cleanIncompleteMarkers("hello `code")
        #expect(!cleaned.contains("`"))
    }

    @Test("Preserves complete markers")
    func completeMarkers() {
        let cleaned = InlineParser.cleanIncompleteMarkers("**bold** and `code`")
        #expect(cleaned == "**bold** and `code`")
    }

    @Test("Cleans incomplete italic marker")
    func incompleteItalic() {
        let cleaned = InlineParser.cleanIncompleteMarkers("hello *italic")
        // Single * should be removed
        let singleStarCount = cleaned.filter { $0 == "*" }.count
        #expect(singleStarCount % 2 == 0)
    }

    @Test("Handles empty string")
    func emptyString() {
        let result = InlineParser.parse("")
        #expect(result.characters.isEmpty)
    }

    @Test("Streaming mode handles incomplete markers gracefully")
    func streamingMode() {
        let result = InlineParser.parse("hello **world", isStreaming: true)
        // Should not crash, should return some attributed string
        #expect(!result.characters.isEmpty)
    }
}
