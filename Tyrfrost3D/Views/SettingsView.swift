import SwiftUI
struct SettingsView: View {
    @Binding var defaults: AppDefaults
    @Binding var logoImage: UIImage?
    @State private var showPicker = false
    var body: some View {
        Form {
            Section("Betalning") {
                TextField("Swishnummer", text: Binding(get: { defaults.swishNumber }, set: { defaults.swishNumber = $0 })).keyboardType(.numberPad)
                TextField("Moms (%)", value: Binding(get: { defaults.momsPercent }, set: { defaults.momsPercent = $0 }), format: .number)
            }
            Section("Maskin & kalkyl") {
                TextField("Timpris (kr/h)", value: Binding(get: { defaults.timpris }, set: { defaults.timpris = $0 }), format: .number)
                TextField("Vinstpåslag (%)", value: Binding(get: { defaults.vinstPaaslagPercent }, set: { defaults.vinstPaaslagPercent = $0 }), format: .number)
                Picker("Leverans", selection: Binding(get: { defaults.defaultLeverans }, set: { defaults.defaultLeverans = $0 })) {
                    Text("Avhämtning").tag("Avhämtning"); Text("Frakt").tag("Frakt")
                }
                TextField("Frakt (kr)", value: Binding(get: { defaults.standardFrakt }, set: { defaults.standardFrakt = $0 }), format: .number)
                TextField("Maskinunderhåll (kr/print)", value: Binding(get: { defaults.maintenancePerPrint }, set: { defaults.maintenancePerPrint = $0 }), format: .number)
            }
            Section("Material") {
                Text("Antal material: \(defaults.materials.count)")
                NavigationLink("Byt material via CSV", destination: CSVImportHelp())
            }
            Section("Logga") {
                Button("Välj logga (bild)") { showPicker = true }
                if let logoImage { Image(uiImage: logoImage).resizable().scaledToFit().frame(height: 80) }
                else { Text("Ingen logga vald").foregroundColor(.secondary) }
            }
            Section { Button("Spara inställningar") {
                if let img = logoImage, let png = img.pngData() { defaults.logoImagePNG = png }
                defaults.save()
            } }
        }
        .navigationTitle("Inställningar")
        .sheet(isPresented: $showPicker) { ImagePicker(image: $logoImage) }
    }
}
struct CSVImportHelp: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CSV-format").font(.headline)
            Text("Varje rad: Namn;PrisPerGram  — eller  Namn,PrisPerGram  — eller  Namn\\tPrisPerGram")
            Text("Ex:").font(.subheadline)
            Text(\"\"\"PLA;0.40
PETG;0.55
ABS;0.60\"\"\").font(.system(.body, design: .monospaced))
            Spacer(); Text("Gå tillbaka och importera via knappen i huvudvyn.").foregroundColor(.secondary)
        }.padding()
    }
}
