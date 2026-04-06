import SwiftUI

/// Caret style for streaming indicator, matching React Streamdown's `caret` prop.
public enum StreamdownCaret: Sendable {
    /// Block cursor (▌) — default
    case block
    /// Circle cursor (●)
    case circle
}

/// Animated blinking cursor shown at the end of the last block during streaming.
public struct StreamingCursorView: View {
    let style: StreamdownCaret
    @State private var isVisible = true

    public init(style: StreamdownCaret = .block) {
        self.style = style
    }

    public var body: some View {
        Text(caretCharacter)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(), value: isVisible)
            .onAppear { isVisible = false }
    }

    private var caretCharacter: String {
        switch style {
        case .block: return "\u{258C}"
        case .circle: return "\u{25CF}"
        }
    }
}
