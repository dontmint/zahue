import AppKit
import Foundation
import SwiftUI

enum ThemeModeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    static let systemThemeID = "__system__"
    static let fontSizeOptions: [Int] = [100, 110, 125, 150]

    @Published var themes: [ThemeDefinition] = []
    /// `__system__` means follow macOS appearance and do not apply a catalog theme yet.
    @Published var selectedThemeID: String = AppState.systemThemeID
    @Published var themeFilter: ThemeModeFilter = .all
    @Published var themeQuery: String = ""

    @Published var fontFamilies: [SystemFontFamily] = []
    @Published var selectedFontFamily: String = "SF Pro Text"
    @Published var selectedFontWeight: Int = 400
    @Published var selectedFontSizePercent: Int = 100
    @Published var fontQuery: String = ""

    @Published var zaloPath: String = "/Applications/Zalo.app"
    @Published var status = InstallerStatus()
    @Published var logText: String = ""
    @Published var isBusy: Bool = false
    @Published var lastError: String?
    @Published var showLogs: Bool = false
    @Published var showThemePicker: Bool = false
    @Published var showFontPicker: Bool = false
    @Published var palette: ThemePalette = .system()

    var selectedTheme: ThemeDefinition? {
        guard selectedThemeID != Self.systemThemeID else { return nil }
        return themes.first { $0.id == selectedThemeID }
    }

    var isSystemThemeSelected: Bool {
        selectedThemeID == Self.systemThemeID
    }

    var filteredThemes: [ThemeDefinition] {
        themes.filter { theme in
            switch themeFilter {
            case .all: break
            case .light: if !theme.isLight { return false }
            case .dark: if theme.isLight { return false }
            }
            if themeQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            let q = themeQuery.lowercased()
            return theme.name.lowercased().contains(q)
                || theme.family.lowercased().contains(q)
                || theme.id.lowercased().contains(q)
        }
    }

    var filteredFonts: [SystemFontFamily] {
        if fontQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return fontFamilies }
        let q = fontQuery.lowercased()
        return fontFamilies.filter { $0.name.lowercased().contains(q) }
    }

    var selectedFont: SystemFontFamily? {
        fontFamilies.first { $0.name == selectedFontFamily }
    }

    var availableWeights: [SystemFontWeight] {
        selectedFont?.weights ?? [SystemFontWeight(id: 400, name: "Regular", weight: 400)]
    }

    var currentThemeName: String {
        if let name = status.themeName, !name.isEmpty { return name }
        if let id = status.themeId, let theme = themes.first(where: { $0.id == id }) {
            return theme.name
        }
        return status.themed ? (status.themeId ?? "Custom") : "Original Zalo"
    }

    var headerTitle: String {
        if isSystemThemeSelected { return "System Default" }
        return selectedTheme?.name ?? "Select a theme"
    }

    var headerSubtitle: String {
        if isSystemThemeSelected {
            return "Follows macOS Light / Dark · pick a theme to preview"
        }
        if let theme = selectedTheme {
            return "\(theme.family) · \(theme.mode) · live preview"
        }
        return "\(themes.count) themes available"
    }

    func bootstrap() {
        themes = ThemeCatalog.load()
        fontFamilies = FontCatalog.loadFamilies()

        if let maple = fontFamilies.first(where: { $0.name.localizedCaseInsensitiveContains("Maple Mono") }) {
            selectedFontFamily = maple.name
            selectedFontWeight = maple.weights.first(where: { $0.weight == 600 })?.weight
                ?? maple.weights.last?.weight
                ?? 400
        } else if let sf = fontFamilies.first(where: { $0.name == "SF Pro Text" || $0.name == ".AppleSystemUIFont" || $0.name == "System Font" }) {
            selectedFontFamily = sf.name
            selectedFontWeight = sf.weights.first(where: { $0.weight == 400 })?.weight ?? 400
        } else if let first = fontFamilies.first {
            selectedFontFamily = first.name
            selectedFontWeight = first.weights.first(where: { $0.weight == 400 })?.weight ?? first.weights.first?.weight ?? 400
        }

        selectedThemeID = Self.systemThemeID
        refreshPalette()
    }

    func selectSystemTheme() {
        selectedThemeID = Self.systemThemeID
        refreshPalette()
    }

    func selectTheme(id: String) {
        selectedThemeID = id
        refreshPalette()
    }

    func refreshPalette() {
        if let theme = selectedTheme {
            palette = .preview(from: theme)
        } else {
            palette = .system()
        }
    }

    func syncWeightForSelectedFont() {
        let weights = availableWeights.map(\.weight)
        if !weights.contains(selectedFontWeight) {
            selectedFontWeight = weights.first(where: { $0 == 400 }) ?? weights.first ?? 400
        }
    }

    func appendLog(_ chunk: String) {
        logText += chunk
        if logText.count > 40_000 {
            let trimmed = String(logText.suffix(32_000))
            if let newline = trimmed.firstIndex(of: "\n") {
                logText = String(trimmed[trimmed.index(after: newline)...])
            } else {
                logText = trimmed
            }
        }
    }

    func clearLog() {
        logText = ""
    }

    func refreshStatus(logOutput: Bool = false) async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            status = try await InstallerService.shared.status(zaloPath: zaloPath) { [weak self] chunk in
                guard logOutput else { return }
                Task { @MainActor in self?.appendLog(chunk) }
            }
            if logOutput {
                appendLog("[status] theme=\(status.themeName ?? status.themeId ?? "none") · font=\(status.fontFamily ?? "-") · backup=\(status.hasBackup ? "yes" : "no")\n")
            }
            // Do not auto-select installed theme into preview; keep user's picker choice.
            if let font = status.fontFamily, fontFamilies.contains(where: { $0.name == font }) {
                selectedFontFamily = font
            }
            if let weight = status.fontWeight {
                selectedFontWeight = weight
                syncWeightForSelectedFont()
            }
            if let size = status.fontSizePercent, Self.fontSizeOptions.contains(size) {
                selectedFontSizePercent = size
            }
            refreshPalette()
        } catch {
            lastError = error.localizedDescription
            appendLog("\n[error] \(error.localizedDescription)\n")
        }
    }

    func applySelectedTheme() async {
        guard let theme = selectedTheme else { return }
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        clearLog()
        showLogs = true
        do {
            try await InstallerService.shared.apply(
                theme: theme,
                zaloPath: zaloPath,
                fontFamily: selectedFontFamily,
                fontWeight: selectedFontWeight,
                fontSizePercent: selectedFontSizePercent
            ) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            await refreshStatus(logOutput: false)
            appendLog("\n[status] applied \(status.themeName ?? theme.name) · font=\(status.fontFamily ?? selectedFontFamily) · size=\(selectedFontSizePercent)%\n")
        } catch {
            lastError = error.localizedDescription
            appendLog("\n[error] \(error.localizedDescription)\n")
        }
    }

    func restoreOriginal() async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        clearLog()
        showLogs = true
        do {
            try await InstallerService.shared.restore(zaloPath: zaloPath) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            await refreshStatus(logOutput: false)
            appendLog("\n[status] restored original Zalo\n")
        } catch {
            lastError = error.localizedDescription
            appendLog("\n[error] \(error.localizedDescription)\n")
        }
    }
}
