import SwiftUI

/// Renders a fenced code block with optional language label and monospace font.
public struct CodeBlockView: View {
    let language: String?
    let content: String
    let isComplete: Bool
    let theme: StreamdownTheme

    public init(language: String?, content: String, isComplete: Bool, theme: StreamdownTheme = .default) {
        self.language = language
        self.content = content
        self.isComplete = isComplete
        self.theme = theme
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .foregroundStyle(theme.codeLanguageColor)
                    .padding(.horizontal, theme.codePadding)
                    .padding(.top, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Text(content)
                        .font(.system(size: theme.codeFontSize, design: .monospaced))
                        .foregroundStyle(theme.codeTextColor)
                        .textSelection(.enabled)
                    if !isComplete {
                        StreamingCursorView()
                    }
                }
                .padding(theme.codePadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.codeCornerRadius))
    }
}
