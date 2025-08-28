import SwiftUI
import UniformTypeIdentifiers
struct ContentView: View {
    @State private var defaults = AppDefaults.load()
    @State private var selectedMaterial: Material = Material.defaults.first!
    @State private var weightG: String = "0"
    @State private var vinstPercent: String = "40"
    @State private var hours: String = "0"
    @State private var timpris: String = "200"
    @State private var delivery: String = "Avhämtning"
    @State private var frakt: String = "69"
    @State private var rabatt: String = "0"
    @State private var momsPercent: String = "25"
    @State private var cadPrice: String = "0"
    @State private var maintenance: String = "10"
    @State private var customer: String = ""
    @State private var result: PricingResult? = nil
    @State private var showPicker = false
    @State private var logoImage: UIImage? = nil
    @State private var showShare = false
    @State private var generatedPDF: Data? = nil
    @State private var showImporter = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Kund") {
                    TextField("Kundnamn", text: $customer)
                    HStack {
                        Button("Välj logga (bild)") { showPicker = true }
                        Spacer()
                        NavigationLink("Inställningar") { SettingsView(defaults: $defaults, logoImage: $logoImage) }
                    }
                    if let logoImage { Image(uiImage: logoImage).resizable().scaledToFit().frame(height: 60) }
                }
                Section("Material") {
                    Picker("Material", selection: $selectedMaterial) {
                        ForEach(defaults.materials) { m in
                            Text("\(m.name) (\(String(format: "%.2f", m.pricePerGram)) kr/g)").tag(m)
                        }
                    }
                    Text("Antal material: \(defaults.materials.count)").font(.footnote).foregroundColor(.secondary)
                    TextField("Pris (kr/g)", text: Binding(
                        get: { String(format: "%.2f", selectedMaterial.pricePerGram) },
                        set: { selectedMaterial.pricePerGram = Double($0.replacingOccurrences(of: ",", with: ".")) ?? selectedMaterial.pricePerGram }
                    )).keyboardType(.decimalPad)
                    TextField("Vikt (g)", text: $weightG).keyboardType(.decimalPad)
                    Button("Importera material (CSV)…") { showImporter = true }
                        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.commaSeparatedText, .plainText], allowsMultipleSelection: false) { res in
                            switch res {
                            case .success(let urls):
                                if let url = urls.first, let text = try? String(contentsOf: url, encoding: .utf8) {
                                    let mats = parseMaterialsCSV(text)
                                    if mats.isEmpty == false {
                                        defaults.materials = mats; defaults.save(); selectedMaterial = mats.first!
                                    }
                                }
                            case .failure: break
                            }
                        }
                }
                Section("Kalkyl") {
                    TextField("Vinstpåslag (%)", text: $vinstPercent).keyboardType(.decimalPad)
                    HStack {
                        TextField("Maskintid (h)", text: $hours).keyboardType(.decimalPad)
                        TextField("Timpris (kr/h)", text: $timpris).keyboardType(.decimalPad)
                    }
                    Picker("Leverans", selection: $delivery) { Text("Avhämtning").tag("Avhämtning"); Text("Frakt").tag("Frakt") }
                    TextField("Frakt (kr)", text: $frakt).keyboardType(.decimalPad)
                    TextField("Rabatt (kr)", text: $rabatt).keyboardType(.decimalPad)
                    TextField("Moms (%)", text: $momsPercent).keyboardType(.decimalPad)
                    HStack {
                        TextField("CAD-pris (kr)", text: $cadPrice).keyboardType(.decimalPad)
                        TextField("Maskinunderhåll (kr)", text: $maintenance).keyboardType(.decimalPad)
                    }
                    Button("Spara som standard") {
                        defaults.momsPercent = Double(momsPercent.replacingOccurrences(of: ",", with: ".")) ?? defaults.momsPercent
                        defaults.timpris = Double(timpris.replacingOccurrences(of: ",", with: ".")) ?? defaults.timpris
                        defaults.vinstPaaslagPercent = Double(vinstPercent.replacingOccurrences(of: ",", with: ".")) ?? defaults.vinstPaaslagPercent
                        defaults.standardFrakt = Double(frakt.replacingOccurrences(of: ",", with: ".")) ?? defaults.standardFrakt
                        defaults.defaultLeverans = delivery
                        defaults.maintenancePerPrint = Double(maintenance.replacingOccurrences(of: ",", with: ".")) ?? defaults.maintenancePerPrint
                        if let img = logoImage, let png = img.pngData() { defaults.logoImagePNG = png }
                        defaults.save()
                    }
                }
                if let r = result {
                    Section("Resultat") {
                        Text(String(format: "Filamentkostnad: %.2f kr", r.filamentWithMargin))
                        Text(String(format: "Maskinkostnad: %.2f kr", r.machineCost))
                        Text(String(format: "Maskinunderhåll: %.2f kr", Double(maintenance.replacingOccurrences(of: ",", with: ".")) ?? 0))
                        if (Double(cadPrice.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 {
                            Text(String(format: "CAD-pris: %.2f kr", Double(cadPrice.replacingOccurrences(of: ",", with: ".")) ?? 0))
                        }
                        if r.discount > 0 { Text(String(format: "Rabatt: -%.2f kr", r.discount)) }
                        if delivery == "Frakt" {
                            Text(String(format: "Frakt: %.2f kr", Double(frakt.replacingOccurrences(of: ",", with: ".")) ?? 0))
                        }
                        Text(String(format: "Moms (%.0f%%): %.2f kr", Double(momsPercent.replacingOccurrences(of: ",", with: ".")) ?? 0, r.moms))
                        Text(String(format: "Öresavrundning: %+0.2f kr", r.roundingAdjustment))
                        Text(String(format: "Total (inkl. moms): %.0f kr", r.roundedTotal)).font(.headline)
                    }
                }
                Section {
                    Button("Beräkna") { calculate() }
                    Button("Förhandsgranska / Dela PDF") { generateAndSharePDF() }.disabled(result == nil)
                }
            }.navigationTitle("Tyrfrost 3D")
        }
        .sheet(isPresented: $showPicker) { ImagePicker(image: $logoImage) }
        .sheet(isPresented: $showShare) { if let data = generatedPDF { ShareSheet(items: [data]) } }
        .onAppear {
            momsPercent = String(format: "%.0f", defaults.momsPercent)
            timpris = String(format: "%.0f", defaults.timpris)
            vinstPercent = String(format: "%.0f", defaults.vinstPaaslagPercent)
            frakt = String(format: "%.0f", defaults.standardFrakt)
            delivery = defaults.defaultLeverans
            maintenance = String(format: "%.0f", defaults.maintenancePerPrint)
            if let png = defaults.logoImagePNG, let img = UIImage(data: png) { logoImage = img }
        }
    }
    func parseMaterialsCSV(_ text: String) -> [Material] {
        var out: [Material] = []
        let lines = text.split(whereSeparator: { $0.isNewline }).map(String.init)
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines); if line.isEmpty { continue }
            let parts: [String]
            if line.contains(";") { parts = line.split(separator: ";", maxSplits: 1).map { String($0) } }
            else if line.contains("\\t") { parts = line.split(separator: "\\t", maxSplits: 1).map { String($0) } }
            else { parts = line.split(separator: ",", maxSplits: 1).map { String($0) } }
            if parts.count == 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let price = Double(parts[1].replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
                if !name.isEmpty, price >= 0 { out.append(Material(name: name, pricePerGram: price)) }
            }
        }
        return out
    }
    func calculate() {
        let inputs = PricingInputs(
            material: selectedMaterial,
            weightG: Double(weightG.replacingOccurrences(of: ",", with: ".")) ?? 0,
            vinstPercent: Double(vinstPercent.replacingOccurrences(of: ",", with: ".")) ?? 0,
            hours: Double(hours.replacingOccurrences(of: ",", with: ".")) ?? 0,
            timpris: Double(timpris.replacingOccurrences(of: ",", with: ".")) ?? 0,
            delivery: delivery,
            frakt: Double(frakt.replacingOccurrences(of: ",", with: ".")) ?? 0,
            rabattKr: Double(rabatt.replacingOccurrences(of: ",", with: ".")) ?? 0,
            momsPercent: Double(momsPercent.replacingOccurrences(of: ",", with: ".")) ?? 0,
            cadPrice: Double(cadPrice.replacingOccurrences(of: ",", with: ".")) ?? 0,
            maintenance: Double(maintenance.replacingOccurrences(of: ",", with: ".")) ?? 0
        )
        result = calcPrice(inputs)
    }
    func generateAndSharePDF() {
        guard let r = result else { return }
        let inv = InvoiceData(
            invoiceNo: InvoiceNumber.next(),
            customer: customer.isEmpty ? "Kund" : customer,
            date: Date(),
            inputs: PricingInputs(
                material: selectedMaterial,
                weightG: Double(weightG.replacingOccurrences(of: ",", with: ".")) ?? 0,
                vinstPercent: Double(vinstPercent.replacingOccurrences(of: ",", with: ".")) ?? 0,
                hours: Double(hours.replacingOccurrences(of: ",", with: ".")) ?? 0,
                timpris: Double(timpris.replacingOccurrences(of: ",", with: ".")) ?? 0,
                delivery: delivery,
                frakt: Double(frakt.replacingOccurrences(of: ",", with: ".")) ?? 0,
                rabattKr: Double(rabatt.replacingOccurrences(of: ",", with: ".")) ?? 0,
                momsPercent: Double(momsPercent.replacingOccurrences(of: ",", with: ".")) ?? 0,
                cadPrice: Double(cadPrice.replacingOccurrences(of: ",", with: ".")) ?? 0,
                maintenance: Double(maintenance.replacingOccurrences(of: ",", with: ".")) ?? 0
            ),
            result: r,
            momsPercent: Double(momsPercent.replacingOccurrences(of: ",", with: ".")) ?? 0,
            swishNumber: defaults.swishNumber,
            logo: logoImage ?? (defaults.logoImagePNG.flatMap { UIImage(data: $0) })
        )
        let data = PDFGenerator.generate(invoice: inv)
        generatedPDF = data; showShare = true
    }
}
