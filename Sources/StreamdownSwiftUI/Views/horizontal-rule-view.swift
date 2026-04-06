import SwiftUI

/// Renders a horizontal rule (---, ***, ___) as a divider.
public struct HorizontalRuleView: View {
    let theme: StreamdownTheme

    public init(theme: StreamdownTheme = .default) {
        self.theme = theme
    }

    public var body: some View {
        Divider()
            .foregroundStyle(theme.horizontalRuleColor)
            .padding(.vertical, 8)
    }
}
