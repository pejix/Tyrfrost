import Foundation

private struct V3 { var x: Double; var y: Double; var z: Double }
private func cross(_ a: V3, _ b: V3) -> V3 { .init(x: a.y*b.z - a.z*b.y, y: a.z*b.x - a.x*b.z, z: a.x*b.y - a.y*b.x) }
private func dot(_ a: V3, _ b: V3) -> Double { a.x*b.x + a.y*b.y + a.z*b.z }

/// En väldigt enkel OBJ-volymberäkning (mm^3). Kräver slutet triangulerat mesh, annars blir resultatet felaktigt.
func objVolumeMM3(from text: String) -> Double? {
    var verts: [V3] = []; verts.reserveCapacity(1000)
    var faces: [[Int]] = []
    for raw in text.split(whereSeparator: \.isNewline) {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("v ") {
            let p = s.split(separator: " ").map(String.init)
            if p.count >= 4, let x = Double(p[1]), let y = Double(p[2]), let z = Double(p[3]) {
                verts.append(.init(x: x, y: y, z: z))
            }
        } else if s.hasPrefix("f ") {
            let parts = s.dropFirst(2).split(separator: " ").map(String.init)
            var idxs: [Int] = []
            for part in parts {
                let first = part.split(separator: "/").first ?? ""
                if let i = Int(first) { idxs.append(i) } // 1-baserad
            }
            if idxs.count >= 3 { faces.append(idxs) }
        }
    }
    if verts.isEmpty || faces.isEmpty { return nil }
    var vol6: Double = 0.0
    for f in faces {
        // triangulera fan (v0, v[i], v[i+1])
        let v0 = verts[f[0]-1]
        for i in 1..<(f.count-1) {
            let v1 = verts[f[i]-1], v2 = verts[f[i+1]-1]
            vol6 += dot(v0, cross(v1, v2))
        }
    }
    return abs(vol6) / 6.0
}