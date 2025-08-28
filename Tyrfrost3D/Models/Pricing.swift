import Foundation
struct PricingInputs {
    var material: Material
    var weightG: Double
    var vinstPercent: Double
    var hours: Double
    var timpris: Double
    var delivery: String
    var frakt: Double
    var rabattKr: Double
    var momsPercent: Double
    var cadPrice: Double
    var maintenance: Double
}
struct PricingResult {
    let rawFilament: Double
    let filamentWithMargin: Double
    let machineCost: Double
    let discount: Double
    let pretax: Double
    let moms: Double
    let total: Double
    let roundedTotal: Double
    let roundingAdjustment: Double
}
func clampDiscount(_ discount: Double, subtotal: Double) -> Double {
    guard discount > 0 else { return 0 }
    return min(discount, max(0, subtotal))
}
func calcPrice(_ i: PricingInputs) -> PricingResult {
    let rawFilament = i.material.pricePerGram * i.weightG
    let filamentWithMargin = rawFilament * (1.0 + i.vinstPercent/100.0)
    let machineCost = i.hours * i.timpris
    let subtotal = filamentWithMargin + machineCost + i.cadPrice + i.maintenance
    let discount = clampDiscount(i.rabattKr, subtotal: subtotal)
    let afterDiscount = max(0, subtotal - discount)
    let pretax = afterDiscount + (i.delivery == "Frakt" ? i.frakt : 0.0)
    let moms = pretax * (i.momsPercent/100.0)
    let total = pretax + moms
    let roundedTotal = total.rounded()
    let roundingAdjustment = roundedTotal - total
    return PricingResult(rawFilament: rawFilament, filamentWithMargin: filamentWithMargin, machineCost: machineCost, discount: discount, pretax: pretax, moms: moms, total: total, roundedTotal: roundedTotal, roundingAdjustment: roundingAdjustment)
}
