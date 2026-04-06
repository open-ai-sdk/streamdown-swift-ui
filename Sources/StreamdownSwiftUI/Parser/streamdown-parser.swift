import Foundation

/// Incremental, stream-aware markdown parser.
/// Maintains internal state to avoid re-parsing completed blocks.
///
/// Usage:
///   let parser = StreamdownParser()
///   // On each stream delta:
///   let blocks = parser.parse(markdown: accumulatedText)
///   // Or for true incremental:
///   let blocks = parser.append(delta: newDelta)
@MainActor
public final class StreamdownParser {
    /// All parsed blocks. Completed blocks are stable; last block may change.
    public private(set) var blocks: [MarkdownBlock] = []

    /// Full accumulated markdown text.
    public private(set) var fullText: String = ""

    /// Index in fullText where the last completed block ends.
    /// On new delta, only text after this index is re-parsed.
    private var completedOffset: Int = 0

    /// Block counter for generating stable IDs.
    private var blockCounter: Int = 0

    /// Number of blocks that are finalized (won't change).
    private var completedBlockCount: Int = 0

    public init() {}

    /// Parse the full markdown string. Resets state and parses from scratch.
    @discardableResult
    public func parse(_ markdown: String) -> [MarkdownBlock] {
        reset()
        fullText = markdown
        let parsed = parseBlocks(from: markdown)
        blocks = parsed
        return blocks
    }

    /// Append a streaming delta. More efficient than parse() for streaming.
    @discardableResult
    public func append(delta: String) -> [MarkdownBlock] {
        fullText += delta

        // Get the tail text from the completed offset
        let startIndex = fullText.index(fullText.startIndex, offsetBy: completedOffset)
        let tail = String(fullText[startIndex...])

        // Parse the tail with line tracking
        let parseResult = parseBlocksWithLineTracking(from: tail)
        let candidateBlocks = parseResult.blocks

        // Build the new blocks array: keep completed blocks, replace tail
        var newBlocks = Array(blocks.prefix(completedBlockCount))

        for (i, candidate) in candidateBlocks.enumerated() {
            let id = blockID(for: completedBlockCount + i)
            newBlocks.append(withID(candidate, id: id))
        }

        // If we have more than one candidate, the non-last ones are complete
        // Advance completedOffset using actual line counts from the source
        if candidateBlocks.count > 1 {
            let completeCount = candidateBlocks.count - 1

            // Calculate actual character offset from the lines consumed by completed blocks
            let tailLines = tail.components(separatedBy: "\n")
            var totalLinesConsumed = 0
            for i in 0..<completeCount {
                totalLinesConsumed += parseResult.linesConsumed[i]
            }

            // Count characters: sum of line lengths + newlines between them
            // We need to also account for any empty lines between blocks
            var charCount = 0
            for lineIdx in 0..<min(totalLinesConsumed, tailLines.count) {
                charCount += tailLines[lineIdx].count
                if lineIdx < totalLinesConsumed - 1 || lineIdx < tailLines.count - 1 {
                    charCount += 1 // newline
                }
            }
            // Skip trailing empty lines that are between blocks
            while totalLinesConsumed < tailLines.count &&
                  tailLines[totalLinesConsumed].trimmingCharacters(in: .whitespaces).isEmpty {
                charCount += tailLines[totalLinesConsumed].count + 1
                totalLinesConsumed += 1
            }

            completedOffset += charCount
            completedBlockCount += completeCount
            blockCounter = max(blockCounter, completedBlockCount)
        }

        blocks = newBlocks
        return blocks
    }

    /// Reset parser state.
    public func reset() {
        blocks = []
        fullText = ""
        completedOffset = 0
        blockCounter = 0
        completedBlockCount = 0
    }

    // MARK: - Internal Parsing

    /// Parse raw text into blocks. This is stateless — no side effects.
    /// Returns (blocks, lineCountPerBlock) where lineCountPerBlock[i] is the number
    /// of source lines consumed by block i.
    struct ParseResult {
        let blocks: [MarkdownBlock]
        let linesConsumed: [Int]
    }

    func parseBlocksWithLineTracking(from text: String) -> ParseResult {
        let lines = text.components(separatedBy: "\n")
        var result: [MarkdownBlock] = []
        var linesConsumed: [Int] = []
        var i = 0
        let placeholderID = BlockID(value: "tmp")

        while i < lines.count {
            let lineStart = i
            let line = lines[i]

            if isHorizontalRule(line) {
                result.append(.horizontalRule(id: placeholderID))
                i += 1
                linesConsumed.append(i - lineStart)
                continue
            }

            if let heading = parseHeading(line) {
                result.append(.heading(id: placeholderID, level: heading.level, content: heading.content))
                i += 1
                linesConsumed.append(i - lineStart)
                continue
            }

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                let fenceResult = parseCodeFence(lines: lines, startIndex: i)
                result.append(.code(
                    id: placeholderID,
                    language: fenceResult.language,
                    content: fenceResult.content,
                    isComplete: fenceResult.isComplete
                ))
                i = fenceResult.nextIndex
                linesConsumed.append(i - lineStart)
                continue
            }

            if isBulletListItem(line) {
                let listResult = parseBulletList(lines: lines, startIndex: i)
                result.append(.bulletList(id: placeholderID, items: listResult.items))
                i = listResult.nextIndex
                linesConsumed.append(i - lineStart)
                continue
            }

            if isNumberedListItem(line) {
                let listResult = parseNumberedList(lines: lines, startIndex: i)
                result.append(.numberedList(id: placeholderID, items: listResult.items))
                i = listResult.nextIndex
                linesConsumed.append(i - lineStart)
                continue
            }

            if isTableRow(line), i + 1 < lines.count, isTableSeparator(lines[i + 1]) {
                let tableResult = parseTable(lines: lines, startIndex: i)
                result.append(.table(id: placeholderID, headers: tableResult.headers, rows: tableResult.rows))
                i = tableResult.nextIndex
                linesConsumed.append(i - lineStart)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                var textLines: [String] = []
                while i < lines.count {
                    let currentLine = lines[i]
                    let currentTrimmed = currentLine.trimmingCharacters(in: .whitespaces)
                    if currentTrimmed.isEmpty { break }
                    if isHorizontalRule(currentLine) { break }
                    if parseHeading(currentLine) != nil { break }
                    if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") { break }
                    if isBulletListItem(currentLine) { break }
                    if isNumberedListItem(currentLine) { break }
                    if isTableRow(currentLine),
                       i + 1 < lines.count,
                       isTableSeparator(lines[i + 1]) { break }
                    textLines.append(currentLine)
                    i += 1
                }
                if !textLines.isEmpty {
                    result.append(.text(id: placeholderID, content: textLines.joined(separator: "\n")))
                    linesConsumed.append(i - lineStart)
                }
                continue
            }

            i += 1
        }

        return ParseResult(blocks: result, linesConsumed: linesConsumed)
    }

    func parseBlocks(from text: String) -> [MarkdownBlock] {
        let lines = text.components(separatedBy: "\n")
        var result: [MarkdownBlock] = []
        var i = 0
        let placeholderID = BlockID(value: "tmp")

        while i < lines.count {
            let line = lines[i]

            // Horizontal rule: ---, ***, ___ (at least 3 chars, only that char + spaces)
            if isHorizontalRule(line) {
                result.append(.horizontalRule(id: placeholderID))
                i += 1
                continue
            }

            // Heading: # , ## , ###
            if let heading = parseHeading(line) {
                result.append(.heading(id: placeholderID, level: heading.level, content: heading.content))
                i += 1
                continue
            }

            // Code fence: ```
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                let fenceResult = parseCodeFence(lines: lines, startIndex: i)
                result.append(.code(
                    id: placeholderID,
                    language: fenceResult.language,
                    content: fenceResult.content,
                    isComplete: fenceResult.isComplete
                ))
                i = fenceResult.nextIndex
                continue
            }

            // Bullet list: - or *
            if isBulletListItem(line) {
                let listResult = parseBulletList(lines: lines, startIndex: i)
                result.append(.bulletList(id: placeholderID, items: listResult.items))
                i = listResult.nextIndex
                continue
            }

            // Numbered list: 1. 2. etc.
            if isNumberedListItem(line) {
                let listResult = parseNumberedList(lines: lines, startIndex: i)
                result.append(.numberedList(id: placeholderID, items: listResult.items))
                i = listResult.nextIndex
                continue
            }

            // Table: | header | header |
            if isTableRow(line), i + 1 < lines.count, isTableSeparator(lines[i + 1]) {
                let tableResult = parseTable(lines: lines, startIndex: i)
                result.append(.table(id: placeholderID, headers: tableResult.headers, rows: tableResult.rows))
                i = tableResult.nextIndex
                continue
            }

            // Text: anything else (skip empty lines)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                // Collect consecutive non-empty text lines
                var textLines: [String] = []
                while i < lines.count {
                    let currentLine = lines[i]
                    let currentTrimmed = currentLine.trimmingCharacters(in: .whitespaces)
                    if currentTrimmed.isEmpty { break }
                    // Stop if next line starts a different block type
                    if isHorizontalRule(currentLine) { break }
                    if parseHeading(currentLine) != nil { break }
                    if currentLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") { break }
                    if isBulletListItem(currentLine) { break }
                    if isNumberedListItem(currentLine) { break }
                    if isTableRow(currentLine),
                       i + 1 < lines.count,
                       isTableSeparator(lines[i + 1]) { break }
                    textLines.append(currentLine)
                    i += 1
                }
                if !textLines.isEmpty {
                    result.append(.text(id: placeholderID, content: textLines.joined(separator: "\n")))
                }
                continue
            }

            i += 1
        }

        return result
    }
}
