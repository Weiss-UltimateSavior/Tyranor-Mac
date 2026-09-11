import CXP3
import Foundation

enum XP3Archive {
    static func containsRootStartupScript(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }

        guard let header = try? handle.read(upToCount: 19), header.count == 19 else { return false }
        let bytes = [UInt8](header)
        let magic: [UInt8] = [0x58, 0x50, 0x33, 0x0D, 0x0A, 0x20, 0x0A, 0x1A, 0x8B, 0x67, 0x01]
        guard Array(bytes.prefix(11)) == magic else { return false }

        let indexOffset = readUInt64(bytes, at: 11)
        guard indexOffset > 0, indexOffset < .max else { return false }

        guard let index = readIndex(handle: handle, at: indexOffset) else { return false }
        return scan(index)
    }

    private static func readIndex(handle: FileHandle, at offset: UInt64) -> [UInt8]? {
        guard (try? handle.seek(toOffset: offset)) != nil else { return nil }
        guard let flagData = try? handle.read(upToCount: 1), flagData.count == 1 else { return nil }
        let method = flagData[0] & 0x07

        if method == 1 {
            guard let sizeData = try? handle.read(upToCount: 16), sizeData.count == 16 else { return nil }
            let sizes = [UInt8](sizeData)
            let compressedSize = Int(readUInt64(sizes, at: 0))
            let originalSize = Int(readUInt64(sizes, at: 8))
            guard compressedSize > 0, originalSize > 0, compressedSize < 256 * 1024 * 1024 else { return nil }
            guard let compressed = try? handle.read(upToCount: compressedSize),
                  compressed.count == compressedSize else { return nil }
            var output = [UInt8](repeating: 0, count: originalSize)
            var outputLength = UInt(originalSize)
            let result = compressed.withUnsafeBytes { source in
                output.withUnsafeMutableBytes { destination in
                    cxz_uncompress(
                        source.bindMemory(to: UInt8.self).baseAddress,
                        source.count,
                        destination.bindMemory(to: UInt8.self).baseAddress,
                        &outputLength
                    )
                }
            }
            guard result == 0, Int(outputLength) == originalSize else { return nil }
            return output
        }

        if method == 0 {
            guard let sizeData = try? handle.read(upToCount: 8), sizeData.count == 8 else { return nil }
            let size = Int(readUInt64([UInt8](sizeData), at: 0))
            guard size > 0, size < 256 * 1024 * 1024 else { return nil }
            guard let data = try? handle.read(upToCount: size), data.count == size else { return nil }
            return [UInt8](data)
        }

        return nil
    }

    private static func scan(_ index: [UInt8]) -> Bool {
        var position = 0
        while position + 12 <= index.count {
            let magic = String(bytes: index[position..<position + 4], encoding: .ascii)
            let size = Int(readUInt64(index, at: position + 4))
            let dataStart = position + 12
            guard size >= 0, dataStart + size <= index.count else { return false }

            if magic == "File", fileChunkHasStartupScript(index, start: dataStart, size: size) {
                return true
            }
            position = dataStart + size
        }
        return false
    }

    private static func fileChunkHasStartupScript(_ index: [UInt8], start: Int, size: Int) -> Bool {
        var position = start
        let end = start + size
        while position + 12 <= end {
            let magic = String(bytes: index[position..<position + 4], encoding: .ascii)
            let chunkSize = Int(readUInt64(index, at: position + 4))
            let dataStart = position + 12
            guard chunkSize >= 0, dataStart + chunkSize <= end else { return false }

            if magic == "info", chunkSize >= 22 {
                let nameLength = Int(readInt16(index, at: dataStart + 20))
                let nameStart = dataStart + 22
                if nameLength > 0, nameStart + nameLength * 2 <= end {
                    let nameData = Data(index[nameStart..<nameStart + nameLength * 2])
                    if let name = String(data: nameData, encoding: .utf16LittleEndian),
                       name.caseInsensitiveCompare("startup.tjs") == .orderedSame {
                        return true
                    }
                }
            }
            position = dataStart + chunkSize
        }
        return false
    }

    private static func readUInt64(_ bytes: [UInt8], at offset: Int) -> UInt64 {
        var value: UInt64 = 0
        for i in 0..<8 where offset + i < bytes.count {
            value |= UInt64(bytes[offset + i]) << (8 * i)
        }
        return value
    }

    private static func readInt16(_ bytes: [UInt8], at offset: Int) -> Int16 {
        guard offset + 2 <= bytes.count else { return 0 }
        return Int16(bitPattern: UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8))
    }
}
