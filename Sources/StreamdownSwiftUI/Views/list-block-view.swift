import SwiftUI

/// Renders a bullet list block with inline markdown support per item.
public struct BulletListBlockView: View {
    let items: [String]
    let isStreaming: Bool
    let theme: StreamdownTheme

    public init(items: [String], isStreaming: Bool = false, theme: StreamdownTheme = .default) {
        self.items = items
        self.isStreaming = isStreaming
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\u{2022}")
                        .foregroundStyle(theme.listBulletColor)
                    HStack(spacing: 0) {
                        Text(InlineParser.parse(item, isStreaming: isStreaming && index == items.count - 1))
                            .textSelection(.enabled)
                        if isStreaming && index == items.count - 1 {
                            StreamingCursorView()
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
    let theme: StreamdownTheme

    public init(items: [String], isStreaming: Bool = false, theme: StreamdownTheme = .default) {
        self.items = items
        self.isStreaming = isStreaming
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .foregroundStyle(theme.listBulletColor)
                    HStack(spacing: 0) {
                        Text(InlineParser.parse(item, isStreaming: isStreaming && index == items.count - 1))
                            .textSelection(.enabled)
                        if isStreaming && index == items.count - 1 {
                            StreamingCursorView()
                        }
                    }
                }
            }
        }
    }
}
