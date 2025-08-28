# Tyrfrost 3D — Codemagic med App Store Connect API-nyckel

## Sätt upp secrets i Codemagic
- `APP_STORE_CONNECT_API_KEY_ID` – ditt Key ID (ABC123XYZ)
- `APP_STORE_CONNECT_ISSUER_ID` – Issuer ID (UUID)
- `APP_STORE_CONNECT_API_KEY_BASE64` – din .p8-nyckel som Base64 (utan radbrytningar)

## Bundle ID
Projektet är satt till `se.dittnamn.Tyrfrost3D`. Vill du byta? Ändra i Xcode:
**TARGETS → Build Settings → PRODUCT_BUNDLE_IDENTIFIER**, samt skapa app-post i App Store Connect med exakt samma ID.

## Kör
Starta workflow **iOS TestFlight (API key)** så bygger Fastlane och laddar upp till TestFlight.


## Nytt: STL/OBJ-import & automatisk vikt
- I appen: Sektionen **3D-fil (mm)** → Importera STL/OBJ.
- Antaganden: Måtten i filen är i **millimeter**. Volym räknas från mesh-ytor.
- **Infill (%)** används som enkel faktor på volymen (t.ex. 20 % infill → 0.20× massan). Skal/top/botten modelleras inte separat i denna version.
- Densitet hämtas från valt material (kan justeras i UI).

> **STEP/STP:** kräver konvertering till triangulerad mesh (t.ex. server med Open Cascade / kommersiellt API). Jag kan koppla in ett serverflöde eller konvertering i Codemagic-pipelinen om du vill.
