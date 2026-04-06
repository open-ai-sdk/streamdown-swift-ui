import Foundation

// MARK: - Block Detection Helpers

extension StreamdownParser {

    struct HeadingResult {
        let level: Int
        let content: String
    }

    struct CodeFenceResult {
        let language: String?
        let content: String
        let isComplete: Bool
        let nextIndex: Int
    }

    struct ListResult {
        let items: [String]
        let nextIndex: Int
    }

    struct TableResult {
        let headers: [String]
        let rows: [[String]]
        let nextIndex: Int
    }

    func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }
        let chars = Set(trimmed)
        return chars.count == 1 && (chars.contains("-") || chars.contains("*") || chars.contains("_"))
    }

    func parseHeading(_ line: String) -> HeadingResult? {
        if line.hasPrefix("### ") {
            return HeadingResult(level: 3, content: String(line.dropFirst(4)))
        } else if line.hasPrefix("## ") {
            return HeadingResult(level: 2, content: String(line.dropFirst(3)))
        } else if line.hasPrefix("# ") {
            return HeadingResult(level: 1, content: String(line.dropFirst(2)))
        }
        return nil
    }

    func parseCodeFence(lines: [String], startIndex: Int) -> CodeFenceResult {
        let openLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let langStr = String(openLine.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        let language = langStr.isEmpty ? nil : langStr

        var contentLines: [String] = []
        var i = startIndex + 1
        var closed = false

        while i < lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "```" {
                closed = true
                i += 1
                break
            }
            contentLines.append(lines[i])
            i += 1
        }

        return CodeFenceResult(
            language: language,
            content: contentLines.joined(separator: "\n"),
            isComplete: closed,
            nextIndex: i
        )
    }

    func isBulletListItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
    }

    func parseBulletList(lines: [String], startIndex: Int) -> ListResult {
        var items: [String] = []
        var i = startIndex
        while i < lines.count, isBulletListItem(lines[i]) {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            items.append(String(trimmed.dropFirst(2)))
            i += 1
        }
        return ListResult(items: items, nextIndex: i)
    }

    func isNumberedListItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let dotIndex = trimmed.firstIndex(of: ".") else { return false }
        let prefix = trimmed[trimmed.startIndex..<dotIndex]
        guard !prefix.isEmpty, prefix.allSatisfy({ $0.isNumber }) else { return false }
        let afterDot = trimmed.index(after: dotIndex)
        return afterDot < trimmed.endIndex && trimmed[afterDot] == " "
    }

    func parseNumberedList(lines: [String], startIndex: Int) -> ListResult {
        var items: [String] = []
        var i = startIndex
        while i < lines.count, isNumberedListItem(lines[i]) {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if let dotIndex = trimmed.firstIndex(of: ".") {
                let afterDot = trimmed.index(after: dotIndex)
                let content = String(trimmed[afterDot...]).trimmingCharacters(in: .whitespaces)
                items.append(content)
            }
            i += 1
        }
        return ListResult(items: items, nextIndex: i)
    }

    func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1
    }

    func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") else { return false }
        let inner = trimmed.dropFirst().dropLast()
        let cells = inner.split(separator: "|")
        return !cells.isEmpty && cells.allSatisfy { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            return c.allSatisfy({ $0 == "-" || $0 == ":" }) && c.contains("-")
        }
    }

    func parseTable(lines: [String], startIndex: Int) -> TableResult {
        let headers = parseTableCells(lines[startIndex])
        var i = startIndex + 2
        var rows: [[String]] = []
        while i < lines.count, isTableRow(lines[i]) {
            rows.append(parseTableCells(lines[i]))
            i += 1
        }
        return TableResult(headers: headers, rows: rows, nextIndex: i)
    }

    func parseTableCells(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let inner = String(trimmed.dropFirst().dropLast())
        return inner.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - ID Management

    func blockID(for index: Int) -> BlockID {
        BlockID(value: "block-\(index)")
    }

    func withID(_ block: MarkdownBlock, id: BlockID) -> MarkdownBlock {
        switch block {
        case .text(_, let content):
            return .text(id: id, content: content)
        case .heading(_, let level, let content):
            return .heading(id: id, level: level, content: content)
        case .code(_, let language, let content, let isComplete):
            return .code(id: id, language: language, content: content, isComplete: isComplete)
        case .bulletList(_, let items):
            return .bulletList(id: id, items: items)
        case .numberedList(_, let items):
            return .numberedList(id: id, items: items)
        case .table(_, let headers, let rows):
            return .table(id: id, headers: headers, rows: rows)
        case .horizontalRule:
            return .horizontalRule(id: id)
        }
    }
}
