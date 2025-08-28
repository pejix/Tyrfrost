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
