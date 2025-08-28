import Foundation
struct Material: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var pricePerGram: Double
    init(id: UUID = UUID(), name: String, pricePerGram: Double) {
        self.id = id; self.name = name; self.pricePerGram = pricePerGram
    }
    static let defaults: [Material] = [
        .init(name: "PLA", pricePerGram: 0.40),
        .init(name: "PETG", pricePerGram: 0.55),
        .init(name: "ABS", pricePerGram: 0.60)
    ]
}
