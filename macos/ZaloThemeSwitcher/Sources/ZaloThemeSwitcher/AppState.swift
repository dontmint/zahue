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
    @Published var themes: [ThemeDefinition] = []
    @Published var selectedThemeID: String = "everforest-light"
    @Published var themeFilter: ThemeModeFilter = .all
    @Published var themeQuery: String = ""

    @Published var fontFamilies: [SystemFontFamily] = []
    @Published var selectedFontFamily: String = "Maple Mono"
    @Published var selectedFontWeight: Int = 600
    @Published var fontQuery: String = ""

    @Published var zaloPath: String = "/Applications/Zalo.app"
    @Published var status = InstallerStatus()
    @Published var logText: String = ""
    @Published var isBusy: Bool = false
    @Published var lastError: String?
    @Published var showLogs: Bool = false
    @Published var showThemePicker: Bool = false
    @Published var showFontPicker: Bool = false

    var selectedTheme: ThemeDefinition? {
        themes.first { $0.id == selectedThemeID }
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

    func bootstrap() {
        themes = ThemeCatalog.load()
        fontFamilies = FontCatalog.loadFamilies()

        if let maple = fontFamilies.first(where: {
            $0.name.localizedCaseInsensitiveContains("Maple Mono")
        }) {
            selectedFontFamily = maple.name
            if let semi = maple.weights.first(where: { $0.weight == 600 }) {
                selectedFontWeight = semi.weight
            } else {
                selectedFontWeight = maple.weights.last?.weight ?? 400
            }
        } else if let first = fontFamilies.first {
            selectedFontFamily = first.name
            selectedFontWeight = first.weights.first(where: { $0.weight == 400 })?.weight ?? first.weights.first?.weight ?? 400
        }

        if themes.contains(where: { $0.id == "everforest-light" }) {
            selectedThemeID = "everforest-light"
        } else if let first = themes.first {
            selectedThemeID = first.id
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
        // Keep the log bounded, but always cut on a newline so the visible
        // top never starts mid-token (e.g. "ight", from a truncated JSON dump).
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
            if let current = status.themeId, themes.contains(where: { $0.id == current }) {
                selectedThemeID = current
            }
            if let font = status.fontFamily, fontFamilies.contains(where: { $0.name == font }) {
                selectedFontFamily = font
            }
            if let weight = status.fontWeight {
                selectedFontWeight = weight
                syncWeightForSelectedFont()
            }
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
                themeId: theme.id,
                zaloPath: zaloPath,
                fontFamily: selectedFontFamily,
                fontWeight: selectedFontWeight
            ) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            await refreshStatus(logOutput: false)
            appendLog("\n[status] applied \(status.themeName ?? theme.name) · font=\(status.fontFamily ?? selectedFontFamily)\n")
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
