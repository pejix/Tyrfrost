import Foundation

private struct Vec3 { var x: Double; var y: Double; var z: Double }
private func cross(_ a: Vec3, _ b: Vec3) -> Vec3 { .init(x: a.y*b.z - a.z*b.y, y: a.z*b.x - a.x*b.z, z: a.x*b.y - a.y*b.x) }
private func dot(_ a: Vec3, _ b: Vec3) -> Double { a.x*b.x + a.y*b.y + a.z*b.z }

/// Beräkna volym (mm^3) från STL-data (ASCII eller binär). Returnerar nil om misslyckas.
func stlVolumeMM3(from data: Data) -> Double? {
    if data.count < 84 { return nil }
    // Heuristik: testa binär enligt spec (80 byte header, 4 byte tri-count, 50 byte per tri)
    let triCount = data.withUnsafeBytes { ptr -> UInt32 in
        return ptr.load(fromByteOffset: 80, as: UInt32.self)
    }
    let expected = 84 + Int(triCount) * 50
    if expected == data.count {
        return stlBinaryVolumeMM3(from: data)
    }
    // Kan ändå vara binär med "solid"-header som ascii; försök ASCII
    if let str = String(data: data, encoding: .utf8), str.lowercased().contains("facet normal") {
        return stlASCIIVolumeMM3(from: str)
    }
    // Sista chans: försök binär
    return stlBinaryVolumeMM3(from: data)
}

private func stlBinaryVolumeMM3(from data: Data) -> Double? {
    if data.count < 84 { return nil }
    let triCount = data.withUnsafeBytes { $0.load(fromByteOffset: 80, as: UInt32.self) }
    let totalExpected = 84 + Int(triCount) * 50
    if totalExpected > data.count { return nil }
    var volume6: Double = 0.0 // sum of 6*V (triple products)
    data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        let base = raw.baseAddress!
        var off = 84
        for _ in 0..<triCount {
            // skip normal (12 bytes)
            off += 12
            // read 3 vertices (36 bytes)
            let v0x = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v0y = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v0z = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v1x = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v1y = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v1z = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v2x = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v2y = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            let v2z = (base+off).assumingMemoryBound(to: Float.self).pointee; off += 4
            // attr byte count (2)
            off += 2
            let v0 = Vec3(x: Double(v0x), y: Double(v0y), z: Double(v0z))
            let v1 = Vec3(x: Double(v1x), y: Double(v1y), z: Double(v1z))
            let v2 = Vec3(x: Double(v2x), y: Double(v2y), z: Double(v2z))
            volume6 += dot(v0, cross(v1, v2))
        }
    }
    return abs(volume6) / 6.0
}

private func stlASCIIVolumeMM3(from text: String) -> Double? {
    var volume6: Double = 0.0
    var verts: [Vec3] = []
    verts.reserveCapacity(3)
    for line in text.split(whereSeparator: \.isNewline) {
        let s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("vertex") || s.hasPrefix("VERTEX") {
            let parts = s.split(separator: " ").map(String.init)
            guard parts.count >= 4,
                  let x = Double(parts[1]), let y = Double(parts[2]), let z = Double(parts[3]) else { continue }
            verts.append(.init(x: x, y: y, z: z))
            if verts.count == 3 {
                let v0 = verts[0], v1 = verts[1], v2 = verts[2]
                volume6 += dot(v0, cross(v1, v2))
                verts.removeAll(keepingCapacity: true)
            }
        }
    }
    return abs(volume6) / 6.0
}