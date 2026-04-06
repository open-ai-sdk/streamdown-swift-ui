import SwiftUI

/// Renders a plain text block with inline markdown support and optional streaming cursor.
public struct TextBlockView: View {
    let content: String
    let isStreaming: Bool
    let parseIncompleteMarkdown: Bool
    let caret: StreamdownCaret?
    let theme: StreamdownTheme

    public init(
        content: String,
        isStreaming: Bool = false,
        parseIncompleteMarkdown: Bool = true,
        caret: StreamdownCaret? = .block,
        theme: StreamdownTheme = .default
    ) {
        self.content = content
        self.isStreaming = isStreaming
        self.parseIncompleteMarkdown = parseIncompleteMarkdown
        self.caret = caret
        self.theme = theme
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(InlineParser.parse(content, isStreaming: isStreaming && parseIncompleteMarkdown))
                .textSelection(.enabled)
            if isStreaming, let caret {
                StreamingCursorView(style: caret)
            }
        }
    }
}
