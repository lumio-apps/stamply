<div align="center">

<img src="assets/icon/icon.png" alt="Stamply icon" width="112">

# Stamply – Visa Checker

**Do I need a visa? Find out in seconds — even offline.**

Visa and entry requirements for **199 passports** to every destination.
Visa-free, visa on arrival, ETA, e-Visa or visa required — with the allowed stay where it is known.

No ads. No tracking. No account. Free and open source.

[![Latest release](https://img.shields.io/github/v/release/lumio-apps/stamply?label=Download%20APK&color=C2441E)](https://github.com/lumio-apps/stamply/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-1B2A4A.svg)](LICENSE)
![Platform: Android](https://img.shields.io/badge/Platform-Android-3DDC84)
![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B)
![Works offline](https://img.shields.io/badge/Works-Offline-2E8B6E)

</div>

## Screenshots

<p align="center">
  <img src="screenshots/home.jpg" alt="Check screen: pick your passport and destination" width="200">
  <img src="screenshots/explore.jpg" alt="Explore screen: every destination for your passport" width="200">
  <img src="screenshots/settings.jpg" alt="Settings: theme and visa data updates" width="200">
  <img src="screenshots/about.jpg" alt="About, privacy and data source" width="200">
</p>

## Features

### ✅ Check
- Pick your **passport** and **destination** from a searchable list of 199 countries
- **Swap** them with one tap
- Clear result card styled like a passport stamp
- **Allowed stay** in days, where available
- **Before you fly** tips: passport validity, return ticket, proof of funds, and a warning about fake e-Visa websites
- **Recent checks** with their status at a glance

### 🌍 Explore
- Every destination for your passport in one list
- See how many countries you can visit **without a visa in advance**
- Filter by status: Visa-free, Visa on arrival, ETA, e-Visa, Visa required
- Search any destination

### 🔖 Saved
- Bookmark trips from the result screen
- Swipe to remove

### ⚙️ Settings
- Light, dark or system theme
- **Update data**: download the latest visa data with one tap
- In-app **Check for updates** (GitHub APK)

## How the data works

| | |
| --- | --- |
| **Built in** | All visa data ships inside the app, so Stamply works with no internet at all — even at the airport. |
| **Optional update** | **Settings → Update data** downloads one static file, [`assets/data/visa_data.json`](assets/data/visa_data.json), from this repository. No server, no account, no personal data sent. |
| **Monthly refresh** | A GitHub Action ([`update-data.yml`](.github/workflows/update-data.yml)) rebuilds the file from the open [Passport Index Data](https://github.com/imorte/passport-index-data) on the 1st of every month. |

Rebuild the data by hand:

```bash
python3 tool/build_data.py
```

> [!IMPORTANT]
> Stamply gives **general guidance only**. Visa rules change often. Always confirm with the embassy or the official government website of your destination before you travel.

## Privacy

- ❌ No ads
- ❌ No analytics, crash reporting or tracking
- ❌ No account or sign-in
- ✅ Your passport, saved trips and recent checks stay on your device
- 🌐 Internet is used **only** when you tap **Update data** or **Check for updates**

Full policy: [PRIVACY.md](PRIVACY.md)

## Download

Get the latest APK from **[Releases](https://github.com/lumio-apps/stamply/releases/latest)**.
Google Play and F-Droid versions are coming soon.

## Build from source

Requirements: [Flutter](https://flutter.dev) (stable channel) and Java 17.

```bash
git clone https://github.com/lumio-apps/stamply.git
cd stamply
flutter pub get
flutter analyze
flutter build apk --release
```

Google Play build (without the in-app updater):

```bash
flutter build appbundle --release --dart-define=SELF_UPDATE=false
```

### Releases

Pushing a version tag (for example `v0.1.0`) makes GitHub Actions build, sign and publish the APK, plus a Play Store bundle as a workflow download.

Required repository secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

## Project structure

```
lib/
├── main.dart               App entry and bottom navigation
├── theme.dart              Colors, fonts, light and dark themes
├── models.dart             Entry status, visa rule, trip
├── visa_repository.dart    Bundled data + optional download
├── app_state.dart          Saved trips, recent checks, settings
├── update_service.dart     In-app updater (GitHub APK)
├── widgets.dart            Shared UI pieces and the logo
└── pages/                  Check, Explore, Saved, Settings, Result, Country picker
tool/build_data.py          Builds visa_data.json from Passport Index Data
```

## Credits

- Visa data: [Passport Index Data](https://github.com/imorte/passport-index-data), MIT License
- Fonts: [Space Grotesk](https://github.com/floriankarsten/space-grotesk) and [IBM Plex Sans](https://github.com/IBM/plex), SIL Open Font License

## More from Lumio Apps

Privacy-first apps with no ads and no tracking: [lumio-apps.online](https://lumio-apps.online) · [GitHub](https://github.com/lumio-apps)

## License

[MIT](LICENSE) © Lumio Apps
