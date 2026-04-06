import SwiftUI

/// Main entry point for streaming markdown rendering.
/// Parses markdown incrementally and renders blocks with streaming animations.
///
/// Supports closure-based customization for overriding specific block renderers:
/// ```swift
/// StreamdownView(markdown: text, isStreaming: true)
///     .codeRenderer { language, content, isComplete, theme in
///         MyCustomCodeView(language: language, content: content)
///     }
/// ```
public struct StreamdownView: View {
    let markdown: String
    let isStreaming: Bool
    let theme: StreamdownTheme

    // Closure-based renderer overrides
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
        isStreaming: Bool = false,
        theme: StreamdownTheme = .default
    ) {
        self.markdown = markdown
        self.isStreaming = isStreaming
        self.theme = theme
    }

    public var body: some View {
        LazyVStack(alignment: .leading, spacing: theme.blockSpacing) {
            ForEach(Array(parser.blocks.enumerated()), id: \.element.id) { index, block in
                blockView(for: block, isLast: index == parser.blocks.count - 1)
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
                    .id(block.id)
            }
        }
        .animation(.easeIn(duration: 0.15), value: parser.blocks.count)
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

    @ViewBuilder
    private func blockView(for block: MarkdownBlock, isLast: Bool) -> some View {
        switch block {
        case .text(_, let content):
            if let custom = textRenderer {
                custom(content, isStreaming && isLast, theme)
            } else {
                TextBlockView(content: content, isStreaming: isStreaming && isLast, theme: theme)
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
                CodeBlockView(language: language, content: content, isComplete: isComplete, theme: theme)
            }

        case .bulletList(_, let items):
            if let custom = bulletListRenderer {
                custom(items, isStreaming && isLast, theme)
            } else {
                BulletListBlockView(items: items, isStreaming: isStreaming && isLast, theme: theme)
            }

        case .numberedList(_, let items):
            if let custom = numberedListRenderer {
                custom(items, isStreaming && isLast, theme)
            } else {
                NumberedListBlockView(items: items, isStreaming: isStreaming && isLast, theme: theme)
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

extension StreamdownView {
    /// Override the text block renderer.
    public func textRenderer<V: View>(
        @ViewBuilder _ renderer: @escaping (String, Bool, StreamdownTheme) -> V
    ) -> StreamdownView {
        var copy = self
        copy.textRenderer = { content, isStreaming, theme in AnyView(renderer(content, isStreaming, theme)) }
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
