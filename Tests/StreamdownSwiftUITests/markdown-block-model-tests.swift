import Testing
@testable import StreamdownSwiftUI

@Suite("MarkdownBlock Model")
struct MarkdownBlockModelTests {

    @Test("BlockID equality")
    func blockIDEquality() {
        let id1 = BlockID(value: "block-0")
        let id2 = BlockID(value: "block-0")
        let id3 = BlockID(value: "block-1")
        #expect(id1 == id2)
        #expect(id1 != id3)
    }

    @Test("BlockID hashable conformance")
    func blockIDHashable() {
        let id1 = BlockID(value: "block-0")
        let id2 = BlockID(value: "block-0")
        let set: Set<BlockID> = [id1, id2]
        #expect(set.count == 1)
    }

    @Test("MarkdownBlock id property returns correct id")
    func blockIDProperty() {
        let id = BlockID(value: "test-id")
        let textBlock = MarkdownBlock.text(id: id, content: "hello")
        #expect(textBlock.id == id)

        let headingBlock = MarkdownBlock.heading(id: id, level: 1, content: "title")
        #expect(headingBlock.id == id)

        let codeBlock = MarkdownBlock.code(id: id, language: "swift", content: "code", isComplete: true)
        #expect(codeBlock.id == id)

        let bulletBlock = MarkdownBlock.bulletList(id: id, items: ["a", "b"])
        #expect(bulletBlock.id == id)

        let numberedBlock = MarkdownBlock.numberedList(id: id, items: ["a"])
        #expect(numberedBlock.id == id)

        let tableBlock = MarkdownBlock.table(id: id, headers: ["H"], rows: [["V"]])
        #expect(tableBlock.id == id)

        let hrBlock = MarkdownBlock.horizontalRule(id: id)
        #expect(hrBlock.id == id)
    }

    @Test("isComplete is true for non-code blocks")
    func isCompleteNonCode() {
        let id = BlockID(value: "test")
        #expect(MarkdownBlock.text(id: id, content: "").isComplete == true)
        #expect(MarkdownBlock.heading(id: id, level: 1, content: "").isComplete == true)
        #expect(MarkdownBlock.bulletList(id: id, items: []).isComplete == true)
        #expect(MarkdownBlock.horizontalRule(id: id).isComplete == true)
    }

    @Test("isComplete reflects code block state")
    func isCompleteCodeBlock() {
        let id = BlockID(value: "test")
        let incomplete = MarkdownBlock.code(id: id, language: nil, content: "x", isComplete: false)
        let complete = MarkdownBlock.code(id: id, language: nil, content: "x", isComplete: true)
        #expect(incomplete.isComplete == false)
        #expect(complete.isComplete == true)
    }

    @Test("MarkdownBlock equatable conformance")
    func equatable() {
        let id = BlockID(value: "block-0")
        let a = MarkdownBlock.text(id: id, content: "hello")
        let b = MarkdownBlock.text(id: id, content: "hello")
        let c = MarkdownBlock.text(id: id, content: "world")
        #expect(a == b)
        #expect(a != c)
    }
}
