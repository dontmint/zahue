import Foundation

enum InstallerError: LocalizedError {
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .failed(let message): return message
        }
    }
}

/// Fully native Zalo theme installer (no Node.js).
final class InstallerService {
    static let shared = InstallerService()

    private let defaultZalo = "/Applications/Zalo.app"
    private let fm = FileManager.default

    private init() {}

    private var tmpRoot: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("zalo-theme-tmp", isDirectory: true)
    }

    func status(zaloPath: String, onOutput: @escaping (String) -> Void) async throws -> InstallerStatus {
        onOutput("[native] status \(zaloPath)\n")
        var status = InstallerStatus(zaloPath: zaloPath)
        status.zaloExists = isDir(zaloPath)
        status.themeCount = ThemeCatalog.load().count

        guard status.zaloExists else { return status }
        let resources = resourcesDir(zaloPath)
        let appAsar = resources.appendingPathComponent("app.asar")
        let bak = resources.appendingPathComponent("app.asar.bak")
        status.appAsarIsDirectory = isDir(appAsar.path)
        status.hasBackup = isFile(bak.path)

        if let state = readInstalledState(appAsarPath: appAsar) {
            status.themeId = state.themeId
            status.themeName = state.themeName
            status.fontFamily = state.fontFamily
            status.fontWeight = state.fontWeight
            status.fontSizePercent = state.fontSizePercent
            status.themed = true
        }
        return status
    }

    func apply(
        theme: ThemeDefinition,
        zaloPath: String,
        fontFamily: String,
        fontWeight: Int,
        fontSizePercent: Int = 100,
        onOutput: @escaping (String) -> Void
    ) async throws {
        let resources = resourcesDir(zaloPath)
        let appAsar = resources.appendingPathComponent("app.asar")
        let bak = resources.appendingPathComponent("app.asar.bak")
        let extract = tmpRoot.appendingPathComponent("app", isDirectory: true)

        guard isFile(appAsar.path) || isDir(appAsar.path) || isFile(bak.path) else {
            throw InstallerError.failed("Neither app.asar nor app.asar.bak found in \(resources.path)")
        }

        quitZalo(onOutput: onOutput)

        // Fast path: already unpacked + themed (or backup exists)
        if isDir(appAsar.path), readInstalledState(appAsarPath: appAsar) != nil || isFile(bak.path) {
            onOutput("[info] Updating theme assets in existing unpacked app.asar\n")
            try writeThemeAssets(appRoot: appAsar, theme: theme, fontFamily: fontFamily, fontWeight: fontWeight, fontSizePercent: fontSizePercent, onOutput: onOutput)
            try ThemeCSSBuilder.patchIndexHTML(at: appAsar, themeId: theme.id)
            onOutput("[info] Patched \(appAsar.appendingPathComponent("pc-dist/index.html").path)\n")
            onOutput("{\"ok\":true,\"action\":\"switch\",\"themeId\":\"\(theme.id)\"}\n")
            onOutput("\nDone. Applied \(theme.name). Open Zalo PC.\n")
            return
        }

        // Fresh extract path
        if isDir(tmpRoot.path) {
            try? fm.removeItem(at: tmpRoot)
        }
        if isDir(appAsar.path) {
            onOutput("[info] Removing previous unpacked install: \(appAsar.path)\n")
            try fm.removeItem(at: appAsar)
        }
        if isFile(bak.path) {
            if isFile(appAsar.path) { try fm.removeItem(at: appAsar) }
            onOutput("[info] Restoring original app.asar from app.asar.bak\n")
            try fm.moveItem(at: bak, to: appAsar)
        }
        guard isFile(appAsar.path) else {
            throw InstallerError.failed("app.asar missing at \(appAsar.path)")
        }

        try fm.createDirectory(at: tmpRoot, withIntermediateDirectories: true)
        onOutput("[info] Extracting \(appAsar.path)\n")
        try AsarExtractor.extractAll(archiveURL: appAsar, to: extract)
        try writeThemeAssets(appRoot: extract, theme: theme, fontFamily: fontFamily, fontWeight: fontWeight, fontSizePercent: fontSizePercent, onOutput: onOutput)
        try ThemeCSSBuilder.patchIndexHTML(at: extract, themeId: theme.id)
        onOutput("[info] Patched \(extract.appendingPathComponent("pc-dist/index.html").path)\n")

        if !isFile(bak.path) {
            try fm.moveItem(at: appAsar, to: bak)
            onOutput("[info] Backup created: \(bak.path)\n")
        } else if isFile(appAsar.path) {
            try fm.removeItem(at: appAsar)
        }

        try fm.moveItem(at: extract, to: appAsar)
        try? fm.removeItem(at: tmpRoot)
        onOutput("{\"ok\":true,\"action\":\"install\",\"themeId\":\"\(theme.id)\"}\n")
        onOutput("\nDone. Applied \(theme.name). Open Zalo PC.\n")
        if theme.isLight {
            onOutput("Tip: set Zalo appearance to Light for light themes.\n")
        }
    }

    func restore(zaloPath: String, onOutput: @escaping (String) -> Void) async throws {
        let resources = resourcesDir(zaloPath)
        let appAsar = resources.appendingPathComponent("app.asar")
        let bak = resources.appendingPathComponent("app.asar.bak")
        guard isFile(bak.path) else {
            throw InstallerError.failed("No app.asar.bak found. Reinstall Zalo PC to restore.")
        }
        quitZalo(onOutput: onOutput)
        if fm.fileExists(atPath: appAsar.path) {
            try fm.removeItem(at: appAsar)
        }
        try fm.moveItem(at: bak, to: appAsar)
        onOutput("{\"ok\":true,\"action\":\"uninstall\",\"themeId\":null}\n")
        onOutput("\nRestored original app.asar. Open Zalo PC.\n")
    }

    // MARK: - Helpers

    private struct InstalledState: Codable {
        var themeId: String?
        var themeName: String?
        var mode: String?
        var fontFamily: String?
        var fontWeight: Int?
        var fontSizePercent: Int?
    }

    private func writeThemeAssets(
        appRoot: URL,
        theme: ThemeDefinition,
        fontFamily: String,
        fontWeight: Int,
        fontSizePercent: Int,
        onOutput: @escaping (String) -> Void
    ) throws {
        let dest = appRoot.appendingPathComponent("pc-dist/\(ThemeCSSBuilder.assetDirName)", isDirectory: true)
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)
        let sizePercent = min(200, max(80, fontSizePercent))
        let css = ThemeCSSBuilder.css(theme: theme, fontFamily: fontFamily, fontWeight: fontWeight, fontSizePercent: sizePercent)
        let js = ThemeCSSBuilder.js(themeId: theme.id)
        try css.write(to: dest.appendingPathComponent("theme.css"), atomically: true, encoding: .utf8)
        try js.write(to: dest.appendingPathComponent("theme.js"), atomically: true, encoding: .utf8)

        let state: [String: Any] = [
            "themeId": theme.id,
            "themeName": theme.name,
            "mode": theme.mode,
            "fontFamily": fontFamily.isEmpty ? "Maple Mono" : fontFamily,
            "fontWeight": fontWeight == 0 ? 600 : fontWeight,
            "fontSizePercent": sizePercent,
            "installedAt": ISO8601DateFormatter().string(from: Date()),
            "tool": "zalo-theme-switcher",
            "source": "native-swift"
        ]
        let data = try JSONSerialization.data(withJSONObject: state, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: dest.appendingPathComponent(ThemeCSSBuilder.stateFile))

        let legacy = appRoot.appendingPathComponent("pc-dist/zalo-maple-dawn")
        if isDir(legacy.path) {
            try? fm.removeItem(at: legacy)
        }
        onOutput("[info] Copied theme assets → \(dest.path) (\(theme.id), font=\(fontFamily) \(fontWeight), size=\(sizePercent)%)\n")
    }

    private func readInstalledState(appAsarPath: URL) -> InstalledState? {
        guard isDir(appAsarPath.path) else { return nil }
        let stateURL = appAsarPath.appendingPathComponent("pc-dist/\(ThemeCSSBuilder.assetDirName)/\(ThemeCSSBuilder.stateFile)")
        if isFile(stateURL.path),
           let data = try? Data(contentsOf: stateURL),
           let state = try? JSONDecoder().decode(InstalledState.self, from: data) {
            return state
        }
        if isDir(appAsarPath.appendingPathComponent("pc-dist/zalo-maple-dawn").path) {
            return InstalledState(themeId: "rose-pine-dawn", themeName: "Rosé Pine Dawn", mode: "light", fontFamily: "Maple Mono", fontWeight: 600)
        }
        return nil
    }

    private func resourcesDir(_ zaloPath: String) -> URL {
        URL(fileURLWithPath: zaloPath).appendingPathComponent("Contents/Resources")
    }

    private func quitZalo(onOutput: @escaping (String) -> Void) {
        onOutput("[info] Quitting Zalo if running...\n")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        proc.arguments = ["Zalo"]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
    }

    private func isFile(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
    }

    private func isDir(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
