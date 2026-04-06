import SwiftUI

/// Renders a plain text block with inline markdown support and optional streaming cursor.
public struct TextBlockView: View {
    let content: String
    let isStreaming: Bool
    let theme: StreamdownTheme

    public init(content: String, isStreaming: Bool = false, theme: StreamdownTheme = .default) {
        self.content = content
        self.isStreaming = isStreaming
        self.theme = theme
    }

    public var body: some View {
        HStack(spacing: 0) {
            Text(InlineParser.parse(content, isStreaming: isStreaming))
                .textSelection(.enabled)
            if isStreaming {
                StreamingCursorView()
            }
        }
    }
}
