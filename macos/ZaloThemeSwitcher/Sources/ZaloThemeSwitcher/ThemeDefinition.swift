import Foundation
import SwiftUI

struct ThemeDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let mode: String
    let swatches: [Color]

    static let all: [ThemeDefinition] = [
        ThemeDefinition(
            id: "rose-pine-dawn",
            name: "Rosé Pine Dawn",
            subtitle: "Warm light pastel",
            mode: "light",
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
            mode: "dark",
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
            mode: "dark",
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
}
