import Foundation

struct Material: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var pricePerGram: Double
    var densityGPerCm3: Double  // för vikt från volym

    init(id: UUID = UUID(), name: String, pricePerGram: Double, densityGPerCm3: Double) {
        self.id = id
        self.name = name
        self.pricePerGram = pricePerGram
        self.densityGPerCm3 = densityGPerCm3
    }

    static let defaults: [Material] = [
        .init(name: "PLA",  pricePerGram: 0.40, densityGPerCm3: 1.24),
        .init(name: "PETG", pricePerGram: 0.55, densityGPerCm3: 1.27),
        .init(name: "ABS",  pricePerGram: 0.60, densityGPerCm3: 1.04)
    ]
}