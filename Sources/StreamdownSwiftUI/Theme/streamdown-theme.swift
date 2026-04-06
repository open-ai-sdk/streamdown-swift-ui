#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

/// Configurable theme for StreamdownView appearance.
public struct StreamdownTheme: Sendable {
    // MARK: - Typography
    public var bodyFontSize: CGFloat
    public var headingFontSizes: [CGFloat] // [H1, H2, H3]
    public var codeFontSize: CGFloat

    // MARK: - Colors
    public var textColor: Color
    public var codeBackground: Color
    public var codeTextColor: Color
    public var codeLanguageColor: Color
    public var tableBackground: Color
    public var listBulletColor: Color
    public var headingColor: Color
    public var horizontalRuleColor: Color

    // MARK: - Spacing
    public var blockSpacing: CGFloat
    public var listItemSpacing: CGFloat
    public var codePadding: CGFloat
    public var codeCornerRadius: CGFloat

    public init(
        bodyFontSize: CGFloat = 15,
        headingFontSizes: [CGFloat] = [24, 20, 17],
        codeFontSize: CGFloat = 13,
        textColor: Color = .primary,
        codeBackground: Color = Color(white: 0.95, opacity: 1),
        codeTextColor: Color = .primary,
        codeLanguageColor: Color = .secondary,
        tableBackground: Color = Color(white: 0.95, opacity: 1),
        listBulletColor: Color = .secondary,
        headingColor: Color = .primary,
        horizontalRuleColor: Color = .secondary,
        blockSpacing: CGFloat = 12,
        listItemSpacing: CGFloat = 4,
        codePadding: CGFloat = 12,
        codeCornerRadius: CGFloat = 8
    ) {
        self.bodyFontSize = bodyFontSize
        self.headingFontSizes = headingFontSizes
        self.codeFontSize = codeFontSize
        self.textColor = textColor
        self.codeBackground = codeBackground
        self.codeTextColor = codeTextColor
        self.codeLanguageColor = codeLanguageColor
        self.tableBackground = tableBackground
        self.listBulletColor = listBulletColor
        self.headingColor = headingColor
        self.horizontalRuleColor = horizontalRuleColor
        self.blockSpacing = blockSpacing
        self.listItemSpacing = listItemSpacing
        self.codePadding = codePadding
        self.codeCornerRadius = codeCornerRadius
    }

    // MARK: - Presets

    public static let `default` = StreamdownTheme()
}
