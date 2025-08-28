import Foundation
struct InvoiceNumber {
    static func next() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let keyYear = "inv.year"
        let keySeq = "inv.seq"
        let ud = UserDefaults.standard
        let lastYear = ud.integer(forKey: keyYear)
        var seq = ud.integer(forKey: keySeq)
        if lastYear != year { ud.set(year, forKey: keyYear); seq = 0 }
        seq += 1; ud.set(seq, forKey: keySeq)
        return String(format: "3D-%d-%06d", year, seq)
    }
}
