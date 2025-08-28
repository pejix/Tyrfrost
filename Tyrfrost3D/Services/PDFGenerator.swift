import Foundation
import UIKit
import PDFKit
struct InvoiceData {
    let invoiceNo: String
    let customer: String
    let date: Date
    let inputs: PricingInputs
    let result: PricingResult
    let momsPercent: Double
    let swishNumber: String
    let logo: UIImage?
}
final class PDFGenerator {
    static let mm: CGFloat = 72.0 / 25.4
    static func generate(invoice: InvoiceData) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let ctx = UIGraphicsGetCurrentContext()!
            let margin: CGFloat = 18*mm
            var y: CGFloat = margin
            let title = "FAKTURA" as NSString
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
            let invStr = "Fakturanummer: \(invoice.invoiceNo)" as NSString
            invStr.draw(at: CGPoint(x: pageRect.width - margin - invStr.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)]).width, y: y),
                        withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            var logoBottom: CGFloat = y
            if let logo = invoice.logo {
                let maxW = 50*mm; let maxH = 30*mm
                let aspect = logo.size.width / logo.size.height
                var w = maxW, h = maxH
                if aspect > 1 { h = w / aspect } else { w = h * aspect }
                let x = pageRect.width - margin - w
                let top = y
                logo.draw(in: CGRect(x: x, y: top, width: w, height: h))
                logoBottom = top + h
            }
            let headerBand: CGFloat = max(45*mm, (logoBottom - y) + 10*mm)
            let headerLineY = y + headerBand + 20
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setLineWidth(0.7)
            ctx.move(to: CGPoint(x: margin, y: headerLineY))
            ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: headerLineY))
            ctx.strokePath()
            y = headerLineY + 16
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            for line in ["Kund: \(invoice.customer)", "Datum: \(df.string(from: invoice.date))"] {
                (line as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
                y += 14
            }
            let i = invoice.inputs
            let r = invoice.result
            let items = [
                "Material: \(i.material.name)  (vikt: \(String(format: \"%.1f\", i.weightG)) g)",
                String(format: "Filamentkostnad: %.2f kr", r.filamentWithMargin),
                String(format: "Maskintid: %.1f h @ %.2f kr/h = %.2f kr", i.hours, i.timpris, r.machineCost),
                String(format: "Maskinunderhåll: %.2f kr", i.maintenance),
                (i.cadPrice > 0 ? String(format: "CAD-pris: %.2f kr", i.cadPrice) : nil),
                (i.delivery == "Frakt" ? String(format: "Frakt: %.2f kr", i.frakt) : "Leverans: Avhämtning"),
                (r.discount > 0 ? String(format: "Rabatt: -%.2f kr", r.discount) : nil)
            ].compactMap { $0 }
            for line in items {
                (line as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
                y += 14
            }
            y += 6
            ctx.move(to: CGPoint(x: margin, y: y))
            ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
            ctx.strokePath()
            let contentSepY = y
            y += 16
            let rightX = pageRect.width - margin
            func drawRight(_ s: String, font: UIFont = .systemFont(ofSize: 11)) {
                let w = (s as NSString).size(withAttributes: [.font: font]).width
                (s as NSString).draw(at: CGPoint(x: rightX - w, y: y), withAttributes: [.font: font])
                y += 14
            }
            drawRight(String(format: "Summa exkl. moms: %.2f kr", r.pretax))
            drawRight(String(format: "Moms (%.0f%%): %.2f kr", invoice.momsPercent, r.moms))
            drawRight(String(format: "Öresavrundning: %+0.2f kr", r.roundingAdjustment))
            drawRight(String(format: "Att betala (inkl. moms): %.0f kr", r.roundedTotal), font: .systemFont(ofSize: 12, weight: .semibold))
            let msg = "\(invoice.invoiceNo) \(invoice.customer)".trimmingCharacters(in: .whitespaces)
            let payload = buildSwishPayload(amount: r.roundedTotal, message: msg, payee: invoice.swishNumber)
            if let img = qrImage(from: payload, scale: 3) {
                let qrSize: CGFloat = 100
                let qrTop = contentSepY + 4
                img.draw(in: CGRect(x: margin, y: qrTop, width: qrSize, height: qrSize))
                let textX = margin + qrSize + 10
                var ty = qrTop + 12
                ("Swish: \(invoice.swishNumber)" as NSString).draw(at: CGPoint(x: textX, y: ty), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
                ty += 14
                ("Meddelande: \(msg)" as NSString).draw(at: CGPoint(x: textX, y: ty), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
                ty += 14
                ("Belopp: \(Int(r.roundedTotal)) kr" as NSString).draw(at: CGPoint(x: textX, y: ty), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
        }
        return data
    }
}
