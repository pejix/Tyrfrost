import Foundation
import CoreImage
import UIKit
func buildSwishPayload(amount: Double, message: String, payee: String) -> String {
    let amt = String(format: "%.2f", amount).replacingOccurrences(of: ".", with: ",")
    let enc = message.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    return "C\(payee);\(amt);\(enc);0"
}
func qrImage(from string: String, scale: CGFloat = 6) -> UIImage? {
    let data = string.data(using: .utf8)!
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let output = filter.outputImage else { return nil }
    let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    return UIImage(ciImage: transformed)
}
