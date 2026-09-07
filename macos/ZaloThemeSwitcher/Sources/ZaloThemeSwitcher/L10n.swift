import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .vietnamese: return "🇻🇳"
        case .english: return "🇺🇸"
        }
    }

    var accessibilityName: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
}

/// Lightweight in-app localization (Vietnamese default + English).
enum L10n {
    static func t(_ key: Key, _ language: AppLanguage) -> String {
        switch language {
        case .vietnamese: return key.vi
        case .english: return key.en
        }
    }

    enum Key {
        case accent
        case background
        case foreground
        case uiFont
        case fontSize
        case status
        case system
        case systemUpper
        case themesCount(Int)
        case backupOK
        case noBackup
        case refresh
        case restore
        case themes
        case pickThemeHint
        case ready(Int)
        case zaloNotFound
        case showLog
        case hideLog
        case applyTheme
        case working
        case tipLightTheme
        case installerLog
        case clear
        case logPlaceholder
        case searchThemes
        case searchFonts
        case mode
        case done
        case systemDefault
        case followMacOS
        case systemFonts
        case fontPreview
        case weightCount(Int)
        case originalZalo
        case customTheme
        case selectATheme
        case headerSystemSubtitle
        case livePreview(String, String)
        case themesAvailable(Int)
        case filterAll
        case filterLight
        case filterDark
        case languageToggleHint

        var en: String {
            switch self {
            case .accent: return "Accent"
            case .background: return "Background"
            case .foreground: return "Foreground"
            case .uiFont: return "UI font"
            case .fontSize: return "Font size"
            case .status: return "Status"
            case .system: return "System"
            case .systemUpper: return "SYSTEM"
            case .themesCount(let n): return "\(n) themes"
            case .backupOK: return "Backup OK"
            case .noBackup: return "No backup"
            case .refresh: return "Refresh"
            case .restore: return "Restore"
            case .themes: return "Themes"
            case .pickThemeHint: return "Pick a theme to preview it here, then Apply to Zalo"
            case .ready(let fonts): return "Ready · \(fonts) system fonts · native installer"
            case .zaloNotFound: return "Zalo not found"
            case .showLog: return "Show log"
            case .hideLog: return "Hide log"
            case .applyTheme: return "Apply theme"
            case .working: return "Working…"
            case .tipLightTheme: return "Please use the default Light theme in the Zalo app for correct color rendering."
            case .installerLog: return "Installer log"
            case .clear: return "Clear"
            case .logPlaceholder: return "Please use the default Light theme in the Zalo app for correct color rendering.\n\nInstaller output will appear here…"
            case .searchThemes: return "Search themes…"
            case .searchFonts: return "Search fonts…"
            case .mode: return "Mode"
            case .done: return "Done"
            case .systemDefault: return "System Default"
            case .followMacOS: return "Follow macOS Light / Dark"
            case .systemFonts: return "System fonts"
            case .fontPreview: return "Preview — The quick brown fox jumps over 123"
            case .weightCount(let n): return "\(n) weight\(n == 1 ? "" : "s")"
            case .originalZalo: return "Original Zalo"
            case .customTheme: return "Custom"
            case .selectATheme: return "Select a theme"
            case .headerSystemSubtitle: return "Follows macOS Light / Dark · pick a theme to preview"
            case .livePreview(let family, let mode): return "\(family) · \(mode) · live preview"
            case .themesAvailable(let n): return "\(n) themes available"
            case .filterAll: return "All"
            case .filterLight: return "Light"
            case .filterDark: return "Dark"
            case .languageToggleHint: return "Language"
            }
        }

        var vi: String {
            switch self {
            case .accent: return "Màu nhấn"
            case .background: return "Nền"
            case .foreground: return "Chữ"
            case .uiFont: return "Font giao diện"
            case .fontSize: return "Cỡ chữ"
            case .status: return "Trạng thái"
            case .system: return "Hệ thống"
            case .systemUpper: return "HỆ THỐNG"
            case .themesCount(let n): return "\(n) chủ đề"
            case .backupOK: return "Đã có backup"
            case .noBackup: return "Chưa backup"
            case .refresh: return "Làm mới"
            case .restore: return "Khôi phục"
            case .themes: return "Chủ đề"
            case .pickThemeHint: return "Chọn chủ đề để xem trước, rồi Áp dụng vào Zalo"
            case .ready(let fonts): return "Sẵn sàng · \(fonts) font hệ thống · cài đặt gốc"
            case .zaloNotFound: return "Không tìm thấy Zalo"
            case .showLog: return "Hiện nhật ký"
            case .hideLog: return "Ẩn nhật ký"
            case .applyTheme: return "Áp dụng"
            case .working: return "Đang xử lý…"
            case .tipLightTheme: return "Hãy dùng giao diện Sáng mặc định trong Zalo để màu sắc hiển thị đúng."
            case .installerLog: return "Nhật ký cài đặt"
            case .clear: return "Xóa"
            case .logPlaceholder: return "Hãy dùng giao diện Sáng mặc định trong Zalo để màu sắc hiển thị đúng.\n\nNhật ký cài đặt sẽ hiện tại đây…"
            case .searchThemes: return "Tìm chủ đề…"
            case .searchFonts: return "Tìm font…"
            case .mode: return "Chế độ"
            case .done: return "Xong"
            case .systemDefault: return "Mặc định hệ thống"
            case .followMacOS: return "Theo Sáng / Tối của macOS"
            case .systemFonts: return "Font hệ thống"
            case .fontPreview: return "Xem trước — The quick brown fox jumps over 123"
            case .weightCount(let n): return "\(n) độ đậm"
            case .originalZalo: return "Zalo gốc"
            case .customTheme: return "Tùy chỉnh"
            case .selectATheme: return "Chọn một chủ đề"
            case .headerSystemSubtitle: return "Theo Sáng / Tối macOS · chọn chủ đề để xem trước"
            case .livePreview(let family, let mode): return "\(family) · \(mode) · xem trước"
            case .themesAvailable(let n): return "\(n) chủ đề"
            case .filterAll: return "Tất cả"
            case .filterLight: return "Sáng"
            case .filterDark: return "Tối"
            case .languageToggleHint: return "Ngôn ngữ"
            }
        }
    }
}
