import SwiftUI

/// Renders a heading block (H1-H3) with appropriate font sizing.
public struct HeadingBlockView: View {
    let level: Int
    let content: String
    let theme: StreamdownTheme

    public init(level: Int, content: String, theme: StreamdownTheme = .default) {
        self.level = level
        self.content = content
        self.theme = theme
    }

    public var body: some View {
        Text(InlineParser.parse(content, isStreaming: false))
            .font(fontForLevel)
            .fontWeight(.semibold)
            .foregroundStyle(theme.headingColor)
            .textSelection(.enabled)
    }

    private var fontForLevel: Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        default: return .title3
        }
    }
}
