import Foundation

/// Unique identifier for a markdown block, stable across incremental parses.
public struct BlockID: Hashable, Sendable {
    public let value: String

    public init(value: String) {
        self.value = value
    }
}

/// A parsed markdown block with metadata for streaming state.
public enum MarkdownBlock: Identifiable, Sendable, Equatable {
    case text(id: BlockID, content: String)
    case heading(id: BlockID, level: Int, content: String)
    case code(id: BlockID, language: String?, content: String, isComplete: Bool)
    case bulletList(id: BlockID, items: [String])
    case numberedList(id: BlockID, items: [String])
    case table(id: BlockID, headers: [String], rows: [[String]])
    case horizontalRule(id: BlockID)

    public var id: BlockID {
        switch self {
        case .text(let id, _),
             .heading(let id, _, _),
             .code(let id, _, _, _),
             .bulletList(let id, _),
             .numberedList(let id, _),
             .table(let id, _, _),
             .horizontalRule(let id):
            return id
        }
    }

    /// Whether this block may still receive more content from the stream.
    public var isComplete: Bool {
        switch self {
        case .code(_, _, _, let complete):
            return complete
        default:
            return true
        }
    }
}
