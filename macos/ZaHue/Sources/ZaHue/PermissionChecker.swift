import AppKit
import Foundation

/// App Management / write access needed to patch `/Applications/Zalo.app`.
enum ZaloWritePermission: Equatable {
    case unknown
    case granted
    case denied
    case zaloMissing

    var isDenied: Bool {
        self == .denied
    }

    var isGranted: Bool {
        self == .granted
    }
}

enum PermissionChecker {
    /// Probes whether ZaHue can write inside Zalo's Resources (App Management / FDA).
    static func check(zaloPath: String) -> ZaloWritePermission {
        let fm = FileManager.default
        let appURL = URL(fileURLWithPath: zaloPath, isDirectory: true)
        guard fm.fileExists(atPath: appURL.path) else { return .zaloMissing }

        let resources = resourcesDir(for: appURL)
        // Prefer writing into Resources; fall back to Contents if Resources is missing.
        let probeDir = fm.fileExists(atPath: resources.path)
            ? resources
            : appURL.appendingPathComponent("Contents", isDirectory: true)
        guard fm.fileExists(atPath: probeDir.path) else { return .denied }

        let probe = probeDir.appendingPathComponent(".zahue-write-probe-\(UUID().uuidString)")
        do {
            try Data("zahue".utf8).write(to: probe, options: .atomic)
            try? fm.removeItem(at: probe)
            return .granted
        } catch {
            return .denied
        }
    }

    /// Opens System Settings → Privacy & Security → App Management (best-effort deep link).
    @discardableResult
    static func openAppManagementSettings() -> Bool {
        let candidates = [
            // macOS Sequoia / Sonoma System Settings
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AppBundles",
            // Ventura-style
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles",
            // Full Disk Access fallback (also unlocks app-bundle writes on some setups)
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            // Privacy root
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ]

        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return true
            }
        }
        return NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    private static func resourcesDir(for zaloApp: URL) -> URL {
        zaloApp.appendingPathComponent("Contents/Resources", isDirectory: true)
    }
}
