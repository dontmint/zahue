import Foundation

/// Minimal Electron ASAR extractor (unpack only).
/// Format: 8-byte size pickle (UInt32 header length) + header pickle (JSON string) + file bytes.
enum AsarExtractor {
    enum Error: LocalizedError {
        case invalidHeader
        case missingFile(String)
        case io(String)

        var errorDescription: String? {
            switch self {
            case .invalidHeader: return "Invalid ASAR archive header"
            case .missingFile(let path): return "Missing file in ASAR: \(path)"
            case .io(let message): return message
            }
        }
    }

    static func extractAll(archiveURL: URL, to destination: URL) throws {
        let data = try Data(contentsOf: archiveURL)
        guard data.count >= 16 else { throw Error.invalidHeader }

        // size pickle: [payloadSize:UInt32][headerPickleLength:UInt32]
        let headerPickleLength = Int(readUInt32(data, at: 4))
        let headerPickleStart = 8
        let headerPickleEnd = headerPickleStart + headerPickleLength
        guard headerPickleEnd <= data.count else { throw Error.invalidHeader }

        let headerPickle = data.subdata(in: headerPickleStart..<headerPickleEnd)
        // string pickle: [payloadSize:UInt32][strLen:Int32][bytes...]
        guard headerPickle.count >= 8 else { throw Error.invalidHeader }
        let strLen = Int(readInt32(headerPickle, at: 4))
        guard strLen >= 0, 8 + strLen <= headerPickle.count else { throw Error.invalidHeader }
        let jsonData = headerPickle.subdata(in: 8..<(8 + strLen))
        guard let root = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let files = root["files"] as? [String: Any] else {
            throw Error.invalidHeader
        }

        let baseOffset = 8 + headerPickleLength
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        try walk(node: files, relativePath: "", archive: data, baseOffset: baseOffset, destination: destination)
    }

    private static func walk(
        node: [String: Any],
        relativePath: String,
        archive: Data,
        baseOffset: Int,
        destination: URL
    ) throws {
        let fm = FileManager.default
        for (name, value) in node {
            guard let entry = value as? [String: Any] else { continue }
            let childRel = relativePath.isEmpty ? name : "\(relativePath)/\(name)"
            let childURL = destination.appendingPathComponent(childRel)

            if let children = entry["files"] as? [String: Any] {
                try fm.createDirectory(at: childURL, withIntermediateDirectories: true)
                try walk(node: children, relativePath: childRel, archive: archive, baseOffset: baseOffset, destination: destination)
                continue
            }

            // unpacked files live beside archive; skip (Zalo theme files are packed)
            if entry["unpacked"] as? Bool == true {
                continue
            }

            guard let offsetString = entry["offset"] as? String,
                  let size = entry["size"] as? Int,
                  let offset = Int(offsetString) else {
                throw Error.missingFile(childRel)
            }

            let start = baseOffset + offset
            let end = start + size
            guard start >= baseOffset, end <= archive.count else {
                throw Error.io("ASAR slice out of range for \(childRel)")
            }

            try fm.createDirectory(at: childURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try archive.subdata(in: start..<end).write(to: childURL)

            if entry["executable"] as? Bool == true {
                try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: childURL.path)
            }
        }
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        data.withUnsafeBytes { raw in
            raw.loadUnaligned(fromByteOffset: offset, as: UInt32.self).littleEndian
        }
    }

    private static func readInt32(_ data: Data, at offset: Int) -> Int32 {
        data.withUnsafeBytes { raw in
            raw.loadUnaligned(fromByteOffset: offset, as: Int32.self).littleEndian
        }
    }
}
