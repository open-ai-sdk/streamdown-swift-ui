import Testing
@testable import StreamdownSwiftUI

@Suite("Parser Block Detection")
struct ParserBlockDetectionTests {

    @Test("Detects heading levels 1-3")
    @MainActor
    func headings() {
        let parser = StreamdownParser()
        let blocks = parser.parse("# H1\n## H2\n### H3")
        #expect(blocks.count == 3)

        if case .heading(_, let level, let content) = blocks[0] {
            #expect(level == 1)
            #expect(content == "H1")
        } else {
            Issue.record("Expected heading block at index 0")
        }

        if case .heading(_, let level, let content) = blocks[1] {
            #expect(level == 2)
            #expect(content == "H2")
        } else {
            Issue.record("Expected heading block at index 1")
        }

        if case .heading(_, let level, let content) = blocks[2] {
            #expect(level == 3)
            #expect(content == "H3")
        } else {
            Issue.record("Expected heading block at index 2")
        }
    }

    @Test("Detects fenced code block with language")
    @MainActor
    func codeBlock() {
        let parser = StreamdownParser()
        let blocks = parser.parse("```swift\nlet x = 1\n```")
        #expect(blocks.count == 1)

        if case .code(_, let lang, let content, let complete) = blocks[0] {
            #expect(lang == "swift")
            #expect(content == "let x = 1")
            #expect(complete == true)
        } else {
            Issue.record("Expected code block")
        }
    }

    @Test("Detects code block without language")
    @MainActor
    func codeBlockNoLang() {
        let parser = StreamdownParser()
        let blocks = parser.parse("```\nhello world\n```")
        #expect(blocks.count == 1)

        if case .code(_, let lang, let content, let complete) = blocks[0] {
            #expect(lang == nil)
            #expect(content == "hello world")
            #expect(complete == true)
        } else {
            Issue.record("Expected code block")
        }
    }

    @Test("Detects bullet list from consecutive items")
    @MainActor
    func bulletList() {
        let parser = StreamdownParser()
        let blocks = parser.parse("- item 1\n- item 2\n- item 3")
        #expect(blocks.count == 1)

        if case .bulletList(_, let items) = blocks[0] {
            #expect(items.count == 3)
            #expect(items[0] == "item 1")
            #expect(items[1] == "item 2")
            #expect(items[2] == "item 3")
        } else {
            Issue.record("Expected bullet list block")
        }
    }

    @Test("Detects bullet list with asterisk marker")
    @MainActor
    func bulletListAsterisk() {
        let parser = StreamdownParser()
        let blocks = parser.parse("* first\n* second")
        #expect(blocks.count == 1)

        if case .bulletList(_, let items) = blocks[0] {
            #expect(items.count == 2)
        } else {
            Issue.record("Expected bullet list block")
        }
    }

    @Test("Detects numbered list from consecutive items")
    @MainActor
    func numberedList() {
        let parser = StreamdownParser()
        let blocks = parser.parse("1. first\n2. second\n3. third")
        #expect(blocks.count == 1)

        if case .numberedList(_, let items) = blocks[0] {
            #expect(items.count == 3)
            #expect(items[0] == "first")
            #expect(items[1] == "second")
            #expect(items[2] == "third")
        } else {
            Issue.record("Expected numbered list block")
        }
    }

    @Test("Detects table with headers and rows")
    @MainActor
    func table() {
        let md = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        | Bob | 25 |
        """
        let parser = StreamdownParser()
        let blocks = parser.parse(md)
        #expect(blocks.count == 1)

        if case .table(_, let headers, let rows) = blocks[0] {
            #expect(headers.count == 2)
            #expect(headers[0] == "Name")
            #expect(headers[1] == "Age")
            #expect(rows.count == 2)
            #expect(rows[0][0] == "Alice")
        } else {
            Issue.record("Expected table block")
        }
    }

    @Test("Detects horizontal rule variants")
    @MainActor
    func horizontalRule() {
        let parser = StreamdownParser()

        let blocks1 = parser.parse("---")
        #expect(blocks1.count == 1)
        if case .horizontalRule = blocks1[0] {} else {
            Issue.record("Expected horizontal rule for ---")
        }

        let blocks2 = parser.parse("***")
        #expect(blocks2.count == 1)
        if case .horizontalRule = blocks2[0] {} else {
            Issue.record("Expected horizontal rule for ***")
        }

        let blocks3 = parser.parse("___")
        #expect(blocks3.count == 1)
        if case .horizontalRule = blocks3[0] {} else {
            Issue.record("Expected horizontal rule for ___")
        }
    }

    @Test("Text block as fallback for unrecognized content")
    @MainActor
    func textFallback() {
        let parser = StreamdownParser()
        let blocks = parser.parse("Just some regular text here.")
        #expect(blocks.count == 1)

        if case .text(_, let content) = blocks[0] {
            #expect(content == "Just some regular text here.")
        } else {
            Issue.record("Expected text block")
        }
    }

    @Test("Mixed block types in sequence")
    @MainActor
    func mixedBlocks() {
        let md = """
        # Title

        Some text here.

        ```python
        print("hello")
        ```

        - item 1
        - item 2
        """
        let parser = StreamdownParser()
        let blocks = parser.parse(md)
        #expect(blocks.count == 4) // heading, text, code, bullet list
    }

    @Test("Empty input produces no blocks")
    @MainActor
    func emptyInput() {
        let parser = StreamdownParser()
        let blocks = parser.parse("")
        #expect(blocks.isEmpty)
    }

    @Test("Whitespace-only input produces no blocks")
    @MainActor
    func whitespaceOnly() {
        let parser = StreamdownParser()
        let blocks = parser.parse("   \n\n   \n")
        #expect(blocks.isEmpty)
    }
}
