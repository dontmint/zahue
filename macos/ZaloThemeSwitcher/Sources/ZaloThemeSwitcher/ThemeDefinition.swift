import Foundation
import SwiftUI

struct ThemeDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let mode: String
    let accentHex: String
    let backgroundHex: String
    let foregroundHex: String
    let swatches: [Color]

    var accent: Color { Color(hexString: accentHex) }
    var background: Color { Color(hexString: backgroundHex) }
    var foreground: Color { Color(hexString: foregroundHex) }

    static let all: [ThemeDefinition] = [
        ThemeDefinition(
            id: "rose-pine-dawn",
            name: "Rosé Pine Dawn",
            subtitle: "Warm light pastel",
            mode: "Light theme",
            accentHex: "#286983",
            backgroundHex: "#FAF4ED",
            foregroundHex: "#575279",
            swatches: [
                Color(hex: 0xFAF4ED),
                Color(hex: 0x575279),
                Color(hex: 0x286983),
                Color(hex: 0xD7827E),
                Color(hex: 0xEA9D34)
            ]
        ),
        ThemeDefinition(
            id: "rose-pine-moon",
            name: "Rosé Pine Moon",
            subtitle: "Soft dark purple",
            mode: "Dark theme",
            accentHex: "#3E8FB0",
            backgroundHex: "#232136",
            foregroundHex: "#E0DEF4",
            swatches: [
                Color(hex: 0x232136),
                Color(hex: 0xE0DEF4),
                Color(hex: 0x3E8FB0),
                Color(hex: 0xEA9A97),
                Color(hex: 0xC4A7E7)
            ]
        ),
        ThemeDefinition(
            id: "rose-pine",
            name: "Rosé Pine",
            subtitle: "Classic dark",
            mode: "Dark theme",
            accentHex: "#31748F",
            backgroundHex: "#191724",
            foregroundHex: "#E0DEF4",
            swatches: [
                Color(hex: 0x191724),
                Color(hex: 0xE0DEF4),
                Color(hex: 0x31748F),
                Color(hex: 0xEB6F92),
                Color(hex: 0xC4A7E7)
            ]
        )
    ]
}

struct InstallerStatus: Equatable {
    var zaloPath: String = "/Applications/Zalo.app"
    var zaloExists: Bool = false
    var hasBackup: Bool = false
    var themeId: String?
    var themed: Bool = false
    var appAsarIsDirectory: Bool = false
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(hex: UInt(value))
    }
}
