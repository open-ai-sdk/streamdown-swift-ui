import SwiftUI

/// Main entry point for streaming markdown rendering.
/// API mirrors React Streamdown's `<Streamdown>` component.
///
/// ```swift
/// StreamdownView(markdown: text, isAnimating: true)
///     .codeRenderer { language, content, isComplete, theme in
///         MyCustomCodeView(language: language, content: content)
///     }
/// ```
public struct StreamdownView: View {
    let markdown: String
    let isAnimating: Bool
    let animated: Bool
    let caret: StreamdownCaret?
    let parseIncompleteMarkdown: Bool
    let theme: StreamdownTheme

    // Closure-based renderer overrides (SwiftUI equivalent of React `components` prop)
    var textRenderer: ((String, Bool, StreamdownTheme) -> AnyView)?
    var codeRenderer: ((String?, String, Bool, StreamdownTheme) -> AnyView)?
    var headingRenderer: ((Int, String, StreamdownTheme) -> AnyView)?
    var bulletListRenderer: (([String], Bool, StreamdownTheme) -> AnyView)?
    var numberedListRenderer: (([String], Bool, StreamdownTheme) -> AnyView)?
    var tableRenderer: (([String], [[String]], StreamdownTheme) -> AnyView)?
    var horizontalRuleRenderer: ((StreamdownTheme) -> AnyView)?

    @State private var parser = StreamdownParser()
    @State private var previousBlockCount = 0

    public init(
        markdown: String,
        isAnimating: Bool = false,
        animated: Bool = true,
        caret: StreamdownCaret? = .block,
        parseIncompleteMarkdown: Bool = true,
        theme: StreamdownTheme = .default
    ) {
        self.markdown = markdown
        self.isAnimating = isAnimating
        self.animated = animated
        self.caret = caret
        self.parseIncompleteMarkdown = parseIncompleteMarkdown
        self.theme = theme
    }

    public var body: some View {
        LazyVStack(alignment: .leading, spacing: theme.blockSpacing) {
            ForEach(Array(parser.blocks.enumerated()), id: \.element.id) { index, block in
                let isLast = index == parser.blocks.count - 1
                blockView(for: block, isLast: isLast)
                    .transition(animated ? .opacity.animation(.easeIn(duration: 0.15)) : .identity)
                    .id(block.id)
            }
        }
        .animation(animated ? .easeIn(duration: 0.15) : nil, value: parser.blocks.count)
        .onChange(of: markdown) { _, newValue in
            if newValue != parser.fullText {
                parser.parse(newValue)
            }
        }
        .onChange(of: parser.blocks.count) { oldCount, _ in
            previousBlockCount = oldCount
        }
        .onAppear {
            if !markdown.isEmpty {
                parser.parse(markdown)
            }
        }
    }

    /// Whether to show caret on the given block.
    private var showCaret: Bool {
        isAnimating && caret != nil
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock, isLast: Bool) -> some View {
        let streaming = isAnimating && isLast
        let incompleteMarkdown = parseIncompleteMarkdown && isAnimating

        switch block {
        case .text(_, let content):
            if let custom = textRenderer {
                custom(content, streaming, theme)
            } else {
                TextBlockView(content: content, isStreaming: streaming, parseIncompleteMarkdown: incompleteMarkdown, caret: showCaret && isLast ? caret : nil, theme: theme)
            }

        case .heading(_, let level, let content):
            if let custom = headingRenderer {
                custom(level, content, theme)
            } else {
                HeadingBlockView(level: level, content: content, theme: theme)
            }

        case .code(_, let language, let content, let isComplete):
            if let custom = codeRenderer {
                custom(language, content, isComplete, theme)
            } else {
                CodeBlockView(language: language, content: content, isComplete: isComplete, caret: showCaret && isLast ? caret : nil, theme: theme)
            }

        case .bulletList(_, let items):
            if let custom = bulletListRenderer {
                custom(items, streaming, theme)
            } else {
                BulletListBlockView(items: items, isStreaming: streaming, parseIncompleteMarkdown: incompleteMarkdown, caret: showCaret && isLast ? caret : nil, theme: theme)
            }

        case .numberedList(_, let items):
            if let custom = numberedListRenderer {
                custom(items, streaming, theme)
            } else {
                NumberedListBlockView(items: items, isStreaming: streaming, parseIncompleteMarkdown: incompleteMarkdown, caret: showCaret && isLast ? caret : nil, theme: theme)
            }

        case .table(_, let headers, let rows):
            if let custom = tableRenderer {
                custom(headers, rows, theme)
            } else {
                TableBlockView(headers: headers, rows: rows, theme: theme)
            }

        case .horizontalRule:
            if let custom = horizontalRuleRenderer {
                custom(theme)
            } else {
                HorizontalRuleView(theme: theme)
            }
        }
    }
}

// MARK: - Closure-Based Customization Modifiers
// SwiftUI equivalent of React Streamdown's `components` prop.

extension StreamdownView {
    /// Override the text block renderer.
    public func textRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping (String, Bool, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.textRenderer = { content, isAnimating, theme in AnyView(renderer(content, isAnimating, theme)) }
        return copy
    }

    /// Override the code block renderer.
    public func codeRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping (String?, String, Bool, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.codeRenderer = { lang, content, complete, theme in AnyView(renderer(lang, content, complete, theme)) }
        return copy
    }

    /// Override the heading block renderer.
    public func headingRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping (Int, String, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.headingRenderer = { level, content, theme in AnyView(renderer(level, content, theme)) }
        return copy
    }

    /// Override the bullet list block renderer.
    public func bulletListRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping ([String], Bool, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.bulletListRenderer = { items, streaming, theme in AnyView(renderer(items, streaming, theme)) }
        return copy
    }

    /// Override the numbered list block renderer.
    public func numberedListRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping ([String], Bool, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.numberedListRenderer = { items, streaming, theme in AnyView(renderer(items, streaming, theme)) }
        return copy
    }

    /// Override the table block renderer.
    public func tableRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping ([String], [[String]], StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.tableRenderer = { headers, rows, theme in AnyView(renderer(headers, rows, theme)) }
        return copy
    }

    /// Override the horizontal rule renderer.
    public func horizontalRuleRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping (StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.horizontalRuleRenderer = { theme in AnyView(renderer(theme)) }
        return copy
    }
}
