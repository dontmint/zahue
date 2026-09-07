import Foundation
import SwiftUI

struct ThemeDefinition: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let family: String
    let variant: String?
    let mode: String
    let accent: String
    let background: String
    let foreground: String

    let red: String?
    let yellow: String?
    let blue: String?
    let cyan: String?
    let magenta: String?
    let green: String?
    let black: String?
    let white: String?
    let brightBlack: String?
    let brightRed: String?
    let brightGreen: String?
    let brightYellow: String?
    let brightBlue: String?
    let brightMagenta: String?
    let brightCyan: String?
    let brightWhite: String?
    let selectionBg: String?
    let selectionFg: String?

    var accentHex: String { accent }
    var backgroundHex: String { background }
    var foregroundHex: String { foreground }
    var subtitle: String { "\(family) · \(mode)" }
    var isLight: Bool { mode == "light" }

    var accentColor: Color { Color(hexString: accent) }
    var backgroundColor: Color { Color(hexString: background) }
    var foregroundColor: Color { Color(hexString: foreground) }

    enum CodingKeys: String, CodingKey {
        case id, name, family, variant, mode, accent, background, foreground
        case red, yellow, blue, cyan, magenta, green, black, white
        case brightBlack = "bright_black"
        case brightRed = "bright_red"
        case brightGreen = "bright_green"
        case brightYellow = "bright_yellow"
        case brightBlue = "bright_blue"
        case brightMagenta = "bright_magenta"
        case brightCyan = "bright_cyan"
        case brightWhite = "bright_white"
        case selectionBg = "selection_bg"
        case selectionFg = "selection_fg"
    }
}

struct InstallerStatus: Equatable {
    var zaloPath: String = "/Applications/Zalo.app"
    var zaloExists: Bool = false
    var hasBackup: Bool = false
    var themeId: String?
    var themeName: String?
    var fontFamily: String?
    var fontWeight: Int?
    var fontSizePercent: Int?
    var themed: Bool = false
    var appAsarIsDirectory: Bool = false
    var themeCount: Int = 0
}

enum ThemeCatalog {
    static func load() -> [ThemeDefinition] {
        let candidates: [URL] = {
            var urls: [URL] = []
            if let resource = Bundle.main.resourceURL {
                urls.append(resource.appendingPathComponent("themes/terminalcolors.json"))
            }
            urls.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Projects/zalo-theme-maple-dawn/themes/terminalcolors.json"))
            urls.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("themes/terminalcolors.json"))
            return urls
        }()

        for url in candidates {
            if let data = try? Data(contentsOf: url),
               let themes = try? JSONDecoder().decode([ThemeDefinition].self, from: data),
               !themes.isEmpty {
                return themes.sorted { a, b in
                    if a.mode != b.mode { return a.mode == "light" }
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
        }
        return []
    }
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
