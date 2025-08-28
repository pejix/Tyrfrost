import Foundation
import UIKit

struct AppDefaults: Codable {
    var swishNumber: String = "0739545662"
    var momsPercent: Double = 25.0
    var timpris: Double = 200.0
    var vinstPaaslagPercent: Double = 40.0
    var standardFrakt: Double = 69.0
    var defaultLeverans: String = "Avhämtning" // "Avhämtning" | "Frakt"
    var maintenancePerPrint: Double = 10.0
    var materials: [Material] = Material.defaults
    var logoImagePNG: Data? = nil

    static func load() -> AppDefaults {
        if let data = UserDefaults.standard.data(forKey: "AppDefaults"),
           let d = try? JSONDecoder().decode(AppDefaults.self, from: data) {
            return d
        }
        return AppDefaults()
    }
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "AppDefaults")
        }
    }
}