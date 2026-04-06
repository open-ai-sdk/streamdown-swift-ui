import SwiftUI

/// Renders a markdown table using SwiftUI Grid layout.
public struct TableBlockView: View {
    let headers: [String]
    let rows: [[String]]
    let theme: StreamdownTheme

    public init(headers: [String], rows: [[String]], theme: StreamdownTheme = .default) {
        self.headers = headers
        self.rows = rows
        self.theme = theme
    }

    public var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                }
            }
            Divider()
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(cell)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding(theme.codePadding)
        .background(theme.tableBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.codeCornerRadius))
    }
}
