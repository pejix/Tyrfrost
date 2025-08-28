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
    @State private var infillPercent: String = "20"
    @State private var customer: String = ""

    @State private var result: PricingResult? = nil
    @State private var showPicker = false
    @State private var logoImage: UIImage? = nil
    @State private var showShare = false
    @State private var generatedPDF: Data? = nil
    @State private var showImporter = false
    @State private var show3DImporter = false
    @State private var last3DFilename: String? = nil
    @State private var last3DVolumeCm3: Double? = nil

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
                            Text("\(m.name) (\(String(format: "%.2f", m.pricePerGram)) kr/g, densitet \(String(format: "%.2f", m.densityGPerCm3)) g/cm³)").tag(m)
                        }
                    }
                    Text("Antal material: \(defaults.materials.count)").font(.footnote).foregroundColor(.secondary)
                    TextField("Pris (kr/g)", text: Binding(
                        get: { String(format: "%.2f", selectedMaterial.pricePerGram) },
                        set: { selectedMaterial.pricePerGram = Double($0.replacingOccurrences(of: ",", with: ".")) ?? selectedMaterial.pricePerGram }
                    )).keyboardType(.decimalPad)
                    TextField("Densitet (g/cm³)", text: Binding(
                        get: { String(format: "%.2f", selectedMaterial.densityGPerCm3) },
                        set: { selectedMaterial.densityGPerCm3 = Double($0.replacingOccurrences(of: ",", with: ".")) ?? selectedMaterial.densityGPerCm3 }
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
                Section("3D-fil (mm)") {
                    HStack {
                        Button("Importera STL/OBJ…") { show3DImporter = true }
                        if let name = last3DFilename {
                            Spacer(); Text(name).lineLimit(1).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    TextField("Fyllnadsgrad (%)", text: $infillPercent).keyboardType(.decimalPad)
                    if let v = last3DVolumeCm3 {
                        Text(String(format: "Volym: %.2f cm³", v)).font(.footnote)
                        let grams = v * selectedMaterial.densityGPerCm3 * (Double(infillPercent.replacingOccurrences(of: ",", with: ".")) ?? 100) / 100.0
                        Text(String(format: "Beräknad vikt: %.1f g", grams)).font(.footnote)
                    } else {
                        Text("Tips: STL/OBJ antas i millimeter.").font(.footnote).foregroundColor(.secondary)
                    }
                }
                .fileImporter(isPresented: $show3DImporter, allowedContentTypes: [UTType.data, .item], allowsMultipleSelection: false) { res in
                    switch res {
                    case .success(let urls):
                        if let url = urls.first {
                            import3D(url: url)
                        }
                    case .failure: break
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
            }
            .navigationTitle("Tyrfrost 3D")
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
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            let parts: [String]
            if line.contains(";") { parts = line.split(separator: ";", maxSplits: 2).map { String($0) } }
            else if line.contains("\\t") { parts = line.split(separator: "\\t", maxSplits: 2).map { String($0) } }
            else { parts = line.split(separator: ",", maxSplits: 2).map { String($0) } }
            if parts.count >= 2 {
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let price = Double(parts[1].replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
                let dens = (parts.count >= 3) ? (Double(parts[2].replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 1.24) : 1.24
                if !name.isEmpty, price >= 0 {
                    out.append(Material(name: name, pricePerGram: price, densityGPerCm3: dens))
                }
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

    // MARK: - 3D Import
    func import3D(url: URL) {
        last3DFilename = url.lastPathComponent
        do {
            let data = try Data(contentsOf: url)
            let lower = url.pathExtension.lowercased()
            var volMM3: Double? = nil
            if lower == "stl" {
                volMM3 = stlVolumeMM3(from: data)
            } else if lower == "obj" {
                if let s = String(data: data, encoding: .utf8) {
                    volMM3 = objVolumeMM3(from: s)
                }
            } else if lower == "step" || lower == "stp" {
                // TODO: STEP kräver konvertering till mesh (server/SDK). För nu: visa notis.
                volMM3 = nil
            }
            if let vol = volMM3 {
                let volCm3 = vol / 1000.0 // mm^3 -> cm^3
                last3DVolumeCm3 = volCm3
                let fill = (Double(infillPercent.replacingOccurrences(of: ",", with: ".")) ?? 100) / 100.0
                let grams = volCm3 * selectedMaterial.densityGPerCm3 * fill
                weightG = String(format: "%.1f", grams)
            } else {
                last3DVolumeCm3 = nil
            }
        } catch {
            last3DVolumeCm3 = nil
        }
    }
}