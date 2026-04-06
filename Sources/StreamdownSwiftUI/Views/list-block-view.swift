import SwiftUI

/// Renders a bullet list block with inline markdown support per item.
public struct BulletListBlockView: View {
    let items: [String]
    let isStreaming: Bool
    let parseIncompleteMarkdown: Bool
    let caret: StreamdownCaret?
    let theme: StreamdownTheme

    public init(
        items: [String],
        isStreaming: Bool = false,
        parseIncompleteMarkdown: Bool = true,
        caret: StreamdownCaret? = .block,
        theme: StreamdownTheme = .default
    ) {
        self.items = items
        self.isStreaming = isStreaming
        self.parseIncompleteMarkdown = parseIncompleteMarkdown
        self.caret = caret
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isLastItem = isStreaming && index == items.count - 1
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\u{2022}")
                        .foregroundStyle(theme.listBulletColor)
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(InlineParser.parse(item, isStreaming: isLastItem && parseIncompleteMarkdown))
                            .textSelection(.enabled)
                        if isLastItem, let caret {
                            StreamingCursorView(style: caret)
                        }
                    }
                }
            }
        }
    }
}

/// Renders a numbered list block with inline markdown support per item.
public struct NumberedListBlockView: View {
    let items: [String]
    let isStreaming: Bool
    let parseIncompleteMarkdown: Bool
    let caret: StreamdownCaret?
    let theme: StreamdownTheme

    public init(
        items: [String],
        isStreaming: Bool = false,
        parseIncompleteMarkdown: Bool = true,
        caret: StreamdownCaret? = .block,
        theme: StreamdownTheme = .default
    ) {
        self.items = items
        self.isStreaming = isStreaming
        self.parseIncompleteMarkdown = parseIncompleteMarkdown
        self.caret = caret
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isLastItem = isStreaming && index == items.count - 1
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .foregroundStyle(theme.listBulletColor)
                    HStack(alignment: .bottom, spacing: 0) {
                        Text(InlineParser.parse(item, isStreaming: isLastItem && parseIncompleteMarkdown))
                            .textSelection(.enabled)
                        if isLastItem, let caret {
                            StreamingCursorView(style: caret)
                        }
                    }
                }
            }
        }
    }
}
