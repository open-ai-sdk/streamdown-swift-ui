import SwiftUI

/// Animated blinking cursor shown at the end of the last block during streaming.
public struct StreamingCursorView: View {
    @State private var isVisible = true

    public init() {}

    public var body: some View {
        Text("\u{258C}")
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(), value: isVisible)
            .onAppear { isVisible = false }
    }
}
