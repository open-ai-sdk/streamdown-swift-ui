import Testing
@testable import StreamdownSwiftUI

@Suite("Parser Incremental Streaming")
struct ParserIncrementalStreamingTests {

    @Test("append() builds blocks incrementally")
    @MainActor
    func incrementalAppend() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "# Hello")
        _ = parser.append(delta: "\nSome text")
        let blocks = parser.blocks
        #expect(blocks.count == 2)
    }

    @Test("Incomplete code block during streaming")
    @MainActor
    func incompleteCodeBlock() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "```swift\nlet x = 1")
        // No closing fence yet
        #expect(parser.blocks.count == 1)
        if case .code(_, _, _, let complete) = parser.blocks[0] {
            #expect(complete == false)
        } else {
            Issue.record("Expected code block")
        }

        // Now close it
        _ = parser.append(delta: "\n```")
        if case .code(_, _, _, let complete) = parser.blocks[0] {
            #expect(complete == true)
        } else {
            Issue.record("Expected code block")
        }
    }

    @Test("Block IDs remain stable after append")
    @MainActor
    func stableBlockIDs() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "# Title\n")
        let firstID = parser.blocks[0].id
        _ = parser.append(delta: "Some text after")
        #expect(parser.blocks[0].id == firstID)
    }

    @Test("Character-by-character streaming produces valid output")
    @MainActor
    func charByChar() {
        let fullText = "# Hello\nWorld"
        let parser = StreamdownParser()
        for char in fullText {
            _ = parser.append(delta: String(char))
        }
        #expect(!parser.blocks.isEmpty)
    }

    @Test("Streaming list items appear incrementally")
    @MainActor
    func streamingList() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "- first item\n")
        #expect(parser.blocks.count == 1)
        if case .bulletList(_, let items) = parser.blocks[0] {
            #expect(items.count == 1)
        }

        _ = parser.append(delta: "- second item")
        if case .bulletList(_, let items) = parser.blocks[0] {
            #expect(items.count == 2)
        }
    }

    @Test("Reset clears all state")
    @MainActor
    func reset() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "# Title\nSome text")
        #expect(!parser.blocks.isEmpty)
        parser.reset()
        #expect(parser.blocks.isEmpty)
    }

    @Test("parse() resets state before parsing")
    @MainActor
    func parseResets() {
        let parser = StreamdownParser()
        _ = parser.append(delta: "# Old Title")
        let blocks = parser.parse("# New Title")
        #expect(blocks.count == 1)
        if case .heading(_, _, let content) = blocks[0] {
            #expect(content == "New Title")
        }
    }
}
