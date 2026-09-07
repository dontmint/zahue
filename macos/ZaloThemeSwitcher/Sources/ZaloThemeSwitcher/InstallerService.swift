import Foundation

enum InstallerError: LocalizedError {
    case nodeNotFound
    case helperNotFound(String)
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .nodeNotFound:
            return "Node.js not found. Install Node 18+ (Homebrew: brew install node)."
        case .helperNotFound(let path):
            return "Installer helper not found at \(path)"
        case .failed(let message):
            return message
        }
    }
}

final class InstallerService {
    static let shared = InstallerService()

    private init() {}

    func resolveNodeBinary() -> String? {
        if let env = ProcessInfo.processInfo.environment["NODE_BINARY"], FileManager.default.isExecutableFile(atPath: env) {
            return env
        }
        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node"
        ]
        if let hit = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return hit
        }
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        which.arguments = ["node"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        try? which.run()
        which.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    func resolveHelperDirectory() throws -> URL {
        if let env = ProcessInfo.processInfo.environment["ZALO_THEME_HELPER"] {
            let url = URL(fileURLWithPath: env)
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("install.js").path) {
                return url
            }
        }

        if let resource = Bundle.main.resourceURL?.appendingPathComponent("helper"),
           FileManager.default.fileExists(atPath: resource.appendingPathComponent("install.js").path) {
            return resource
        }

        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        var dir = executable.deletingLastPathComponent()
        for _ in 0..<10 {
            let install = dir.appendingPathComponent("install.js")
            if FileManager.default.fileExists(atPath: install.path) {
                return dir
            }
            let parent = dir.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: parent.appendingPathComponent("install.js").path) {
                return parent
            }
            dir = parent
        }

        let homeCandidate = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Projects/zalo-theme-maple-dawn")
        if FileManager.default.fileExists(atPath: homeCandidate.appendingPathComponent("install.js").path) {
            return homeCandidate
        }

        throw InstallerError.helperNotFound("Bundle Resources/helper or repo root")
    }

    @discardableResult
    func run(arguments: [String], onOutput: @escaping (String) -> Void) async throws -> String {
        guard let node = resolveNodeBinary() else { throw InstallerError.nodeNotFound }
        let helper = try resolveHelperDirectory()
        let installJS = helper.appendingPathComponent("install.js")

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: node)
            process.arguments = [installJS.path] + arguments
            process.currentDirectoryURL = helper

            let out = Pipe()
            let err = Pipe()
            process.standardOutput = out
            process.standardError = err

            final class OutputBox: @unchecked Sendable {
                private let lock = NSLock()
                private var value = ""
                func append(_ text: String) {
                    lock.lock(); value += text; lock.unlock()
                }
                func snapshot() -> String {
                    lock.lock(); defer { lock.unlock() }
                    return value
                }
            }
            let box = OutputBox()

            let append: @Sendable (Data) -> Void = { data in
                guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { return }
                box.append(text)
                DispatchQueue.main.async { onOutput(text) }
            }

            out.fileHandleForReading.readabilityHandler = { handle in
                append(handle.availableData)
            }
            err.fileHandleForReading.readabilityHandler = { handle in
                append(handle.availableData)
            }

            process.terminationHandler = { proc in
                out.fileHandleForReading.readabilityHandler = nil
                err.fileHandleForReading.readabilityHandler = nil
                append(out.fileHandleForReading.readDataToEndOfFile())
                append(err.fileHandleForReading.readDataToEndOfFile())
                let combined = box.snapshot()

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: combined)
                } else {
                    let message = combined.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(throwing: InstallerError.failed(message.isEmpty ? "Installer exited with code \(proc.terminationStatus)" : message))
                }
            }

            do {
                DispatchQueue.main.async {
                    onOutput("$ node install.js \(arguments.joined(separator: " "))\n")
                }
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func status(zaloPath: String, onOutput: @escaping (String) -> Void) async throws -> InstallerStatus {
        let output = try await run(arguments: ["status", zaloPath], onOutput: onOutput)
        return parseStatus(from: output, fallbackPath: zaloPath)
    }

    func apply(themeId: String, zaloPath: String, onOutput: @escaping (String) -> Void) async throws {
        _ = try await run(arguments: ["install", themeId, zaloPath], onOutput: onOutput)
    }

    func restore(zaloPath: String, onOutput: @escaping (String) -> Void) async throws {
        _ = try await run(arguments: ["uninstall", zaloPath], onOutput: onOutput)
    }

    private func parseStatus(from output: String, fallbackPath: String) -> InstallerStatus {
        var status = InstallerStatus(zaloPath: fallbackPath)
        guard let data = extractJSONObject(from: output)?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return status
        }
        status.zaloPath = obj["zaloPath"] as? String ?? fallbackPath
        status.zaloExists = obj["zaloExists"] as? Bool ?? false
        status.hasBackup = obj["hasBackup"] as? Bool ?? false
        status.themeId = obj["themeId"] as? String
        status.themed = obj["themed"] as? Bool ?? (status.themeId != nil)
        status.appAsarIsDirectory = obj["appAsarIsDirectory"] as? Bool ?? false
        return status
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end])
    }
}
