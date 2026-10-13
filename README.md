<div align="center">

<img src="assets/icon/icon.png" alt="Stamply icon" width="112">

# Stamply – Visa Checker

**Check visa and entry requirements for 199 passports, fully offline.**
Pick your passport and destination and see at a glance: visa-free, visa on arrival, ETA, e-Visa or visa required.
No ads. No tracking. No account. Free and open source.

[![Latest release](https://img.shields.io/github/v/release/lumio-apps/stamply?label=Download&color=C2441E)](https://github.com/lumio-apps/stamply/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform: Android](https://img.shields.io/badge/Platform-Android-3DDC84)
![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B)

</div>

## Features

- **Check**: choose your passport and destination, swap them with one tap, and get a clear result with a passport-stamp style status card
- **Allowed stay** in days, where the data has it
- **Before you fly** tips: passport validity, return ticket, proof of funds, official e-Visa sites
- **Explore**: every destination for your passport, filtered by status, with search
- **Saved** trips and **recent checks**
- **Works offline**: all visa data is built into the app
- **Update data** in Settings downloads the latest data file from this repository — no server, no account, no personal data sent
- Light and dark theme

## Visa data

Stamply uses the open [Passport Index Data](https://github.com/imorte/passport-index-data) (MIT License), converted to a compact file at `assets/data/visa_data.json` by `tool/build_data.py`.

A GitHub Action (`.github/workflows/update-data.yml`) rebuilds this file on the 1st of every month. The app's **Update data** button downloads the same file from the `main` branch, so users get new rules without an app update.

To rebuild it by hand:

```bash
python3 tool/build_data.py
```

> **Disclaimer:** Stamply gives general guidance only. Visa rules change often. Always confirm with the embassy or the official government website of your destination before you travel.

## Build

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

Google Play build (no in-app updater):

```bash
flutter build appbundle --release --dart-define=SELF_UPDATE=false
```

Releases are built and signed by GitHub Actions when a version tag (for example `v0.1.0`) is pushed. Required secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

## Privacy

See [PRIVACY.md](PRIVACY.md). In short: no data collection, and internet is used only when you tap **Update data** or **Check for updates**.

## Credits

- Visa data: [Passport Index Data](https://github.com/imorte/passport-index-data), MIT License
- Fonts: [Space Grotesk](https://github.com/floriankarsten/space-grotesk) and [IBM Plex Sans](https://github.com/IBM/plex), SIL Open Font License

## License

[MIT](LICENSE) © Lumio Apps
