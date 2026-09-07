import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var themes: [ThemeDefinition] = ThemeDefinition.all
    @Published var selectedThemeID: String = ThemeDefinition.all[0].id
    @Published var zaloPath: String = "/Applications/Zalo.app"
    @Published var status = InstallerStatus()
    @Published var logText: String = ""
    @Published var isBusy: Bool = false
    @Published var lastError: String?
    @Published var showLogs: Bool = true

    var selectedTheme: ThemeDefinition? {
        themes.first { $0.id == selectedThemeID }
    }

    var currentThemeName: String {
        if let id = status.themeId, let theme = themes.first(where: { $0.id == id }) {
            return theme.name
        }
        return status.themed ? (status.themeId ?? "Custom") : "Original Zalo"
    }

    func appendLog(_ chunk: String) {
        logText += chunk
        if logText.count > 20_000 {
            logText = String(logText.suffix(16_000))
        }
    }

    func refreshStatus() async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            status = try await InstallerService.shared.status(zaloPath: zaloPath) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            if let current = status.themeId, themes.contains(where: { $0.id == current }) {
                selectedThemeID = current
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
        do {
            try await InstallerService.shared.apply(themeId: theme.id, zaloPath: zaloPath) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            await refreshStatus()
        } catch {
            lastError = error.localizedDescription
            appendLog("\n[error] \(error.localizedDescription)\n")
        }
    }

    func restoreOriginal() async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            try await InstallerService.shared.restore(zaloPath: zaloPath) { [weak self] chunk in
                Task { @MainActor in self?.appendLog(chunk) }
            }
            await refreshStatus()
        } catch {
            lastError = error.localizedDescription
            appendLog("\n[error] \(error.localizedDescription)\n")
        }
    }
}
