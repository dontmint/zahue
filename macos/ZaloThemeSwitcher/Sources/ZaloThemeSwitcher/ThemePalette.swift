import AppKit
import SwiftUI

/// Live chrome colors for the switcher UI (system appearance or selected theme preview).
struct ThemePalette: Equatable {
    var panel: Color
    var panelSoft: Color
    var panelLine: Color
    var accent: Color
    var foreground: Color
    var muted: Color
    var danger: Color
    var preferredScheme: ColorScheme?
    var isPreviewingCatalogTheme: Bool

    static func system() -> ThemePalette {
        ThemePalette(
            panel: Color(nsColor: .windowBackgroundColor),
            panelSoft: Color(nsColor: .controlBackgroundColor),
            panelLine: Color(nsColor: .separatorColor),
            accent: Color(nsColor: .controlAccentColor),
            foreground: Color(nsColor: .labelColor),
            muted: Color(nsColor: .secondaryLabelColor),
            danger: Color(nsColor: .systemRed),
            preferredScheme: nil,
            isPreviewingCatalogTheme: false
        )
    }

    static func preview(from theme: ThemeDefinition) -> ThemePalette {
        let bg = Color(hexString: theme.background)
        let fg = Color(hexString: theme.foreground)
        let accent = Color(hexString: theme.accent)
        let softHex = HexColor.mix(theme.background, "#FFFFFF", theme.isLight ? 0.45 : 0.06)
        let lineHex = HexColor.mix(theme.background, theme.foreground, theme.isLight ? 0.14 : 0.22)
        let mutedHex = theme.brightBlack ?? HexColor.mix(theme.foreground, theme.background, 0.4)
        let dangerHex = theme.red ?? "#F85552"
        return ThemePalette(
            panel: bg,
            panelSoft: Color(hexString: softHex),
            panelLine: Color(hexString: lineHex),
            accent: accent,
            foreground: fg,
            muted: Color(hexString: mutedHex),
            danger: Color(hexString: dangerHex),
            preferredScheme: theme.isLight ? .light : .dark,
            isPreviewingCatalogTheme: true
        )
    }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue = ThemePalette.system()
}

extension EnvironmentValues {
    var themePalette: ThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

enum HexColor {
    static func mix(_ a: String, _ b: String, _ t: Double) -> String {
        let A = rgb(a)
        let B = rgb(b)
        let r = Int((Double(A.r) + (Double(B.r) - Double(A.r)) * t).rounded())
        let g = Int((Double(A.g) + (Double(B.g) - Double(A.g)) * t).rounded())
        let bl = Int((Double(A.b) + (Double(B.b) - Double(A.b)) * t).rounded())
        return String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(bl))
    }

    static func rgba(_ hex: String, _ alpha: Double) -> String {
        let c = rgb(hex)
        return "rgba(\(c.r), \(c.g), \(c.b), \(String(format: "%.3f", alpha)))"
    }

    static func rgb(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (
            r: Int((value >> 16) & 0xFF),
            g: Int((value >> 8) & 0xFF),
            b: Int(value & 0xFF)
        )
    }

    private static func clamp(_ n: Int) -> Int { max(0, min(255, n)) }
}
