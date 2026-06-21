# 🩸 GlucoTrack — سُكَّري

**Bilingual Blood Glucose Tracking App** — Arabic / English with three display themes and SQLite local storage.

تطبيق ثنائي اللغة لمتابعة قياس السكر في الدم مع تخزين SQLite محلي.

Built with **Flutter 3.22** — produces a native Android APK.

[![APK Build](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml/badge.svg)](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- 📝 **Log blood glucose readings** — value, type (fasting / before meal / after meal / before sleep / after exercise / other), timestamp, notes, carbs, insulin
- ✏️ **Edit & delete readings** — full CRUD on every reading
- 📊 **Interactive charts** — area, line, and bar charts with target-range shading
- 🔀 **Sort readings** — by newest, oldest, highest, lowest
- 🔔 **Reminders** — schedule measurement reminders with quick toggle
- 🎯 **Customizable target range** — personalized min/max for in-range calculations
- 📈 **Statistics** — daily average, time-in-range (TIR), max, min, range, count

### Accessibility & Localization
- 🌐 **Bilingual UI** — Arabic (RTL) and English (LTR) with instant switching
- 🎨 **Three display themes** (switchable in settings):
  - **Classic Medical** (default) — clean teal/white, professional
  - **Modern Youth** — dark mode with vibrant gradients
  - **Elder Friendly** — large fonts, high contrast, thick borders

### Data
- 💾 **Local SQLite storage** via sqflite — works fully offline
- 📱 **Native Android APK** — true native build (Dart → ARM/ARM64)

---

## 📱 Screens

| Screen | Purpose |
|--------|---------|
| 🚀 Onboarding | Choose language, theme, name, diabetes type (3 steps) |
| 🏠 Home | Latest reading hero card + daily stats + recent readings |
| ➕ Add / Edit | Quick-add with ±10 buttons and presets; full edit mode |
| 📊 Chart | Area / line / bar charts + sort + full readings list with actions |
| 🔔 Reminders | Add / toggle / delete reminders with type + time |
| ⚙️ Settings | Language, theme, diabetes type, targets, units, profile |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | **Flutter 3.22** (Material 3) |
| Language | **Dart 3.4** |
| State | **Provider** |
| Database | **sqflite** (SQLite) |
| Charts | **fl_chart** |
| Localization | **flutter_localizations** + custom AppStrings |
| Date formatting | **intl** |
| Icons | **flutter_launcher_icons** + Material Icons |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK 3.22+](https://docs.flutter.dev/get-started/install)
- Android Studio (for SDK + emulator) OR command-line tools
- Java 17

### Run in development
```bash
flutter pub get
flutter run                    # debug mode on connected device/emulator
```

### Build APK locally
```bash
flutter build apk --release    # produces build/app/outputs/flutter-apk/app-release.apk
```

### Generate launcher icons
```bash
flutter pub run flutter_launcher_icons
```

---

## 📦 Building via GitHub Actions

The APK is built automatically by GitHub Actions on tag push or manual trigger.

### Trigger a release
```bash
# Option 1: Push a tag
git tag apk-v1.0.0
git push origin apk-v1.0.0

# Option 2: Manual dispatch
# Go to Actions → "📱 APK Build & Release (Flutter)" → Run workflow
```

### Production signing (optional)
Add these repository secrets (Settings → Secrets and variables → Actions):
- `ANDROID_KEYSTORE_BASE64` — base64-encoded `.keystore` file
- `ANDROID_KEY_ALIAS` — key alias (e.g. `glucotrack`)
- `ANDROID_KEYSTORE_PASSWORD` — keystore password
- `ANDROID_KEY_PASSWORD` — key password

**Generating a signing keystore:**
```bash
keytool -genkey -v -keystore release.keystore -alias glucotrack \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w 0 release.keystore
```

If secrets are not set, a debug keystore is auto-generated for testing.

---

## 📂 Project Structure

```
glucotrack/
├── lib/
│   ├── main.dart                    # Entry point + providers + nav shell
│   ├── models/
│   │   ├── reading.dart             # Reading + ReadingType + ReadingStatus
│   │   ├── reminder.dart            # Reminder
│   │   └── settings.dart            # Settings + Language + ThemeStyle + SortOrder
│   ├── database/
│   │   └── database_helper.dart     # SQLite (sqflite) — readings, reminders, settings
│   ├── providers/
│   │   └── providers.dart           # ReadingsProvider, RemindersProvider, SettingsProviderState
│   ├── i18n/
│   │   └── strings.dart             # AR + EN translations (~150 keys)
│   ├── themes/
│   │   └── app_theme.dart           # Classic / Modern / Elder color systems
│   ├── screens/
│   │   ├── onboarding_screen.dart   # 3-step setup
│   │   ├── home_screen.dart         # Hero card + stats + recent list
│   │   ├── add_reading_screen.dart  # Dual-mode: add OR edit
│   │   ├── chart_screen.dart        # 3 chart types + sort + list
│   │   ├── reminders_screen.dart    # Add / toggle / delete
│   │   └── settings_screen.dart     # Full settings UI
│   └── widgets/
│       └── reading_actions.dart     # Edit/Delete popup menu
├── android/                         # Android-specific config (Gradle, manifest, icons)
├── assets/icons/                    # App icons
├── pubspec.yaml                     # Flutter dependencies
├── analysis_options.yaml
└── .github/workflows/apk-build.yml  # CI: build + release APK
```

---

## 📋 Database Schema

The app uses SQLite with 4 tables (mirrors the original Prisma schema):

- **readings** — `id, value, type, timestamp, notes, carbs, insulin`
- **reminders** — `id, time, label, type, enabled`
- **settings** — singleton row with `language, theme, diabetes_type, target_min, target_max, unit, user_name, onboarded`
- **sync_state** — reserved for future Google Drive sync

Database file location on Android:
`/data/data/com.wissamza.glucotrack/databases/glucotrack.db`

---

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License

MIT © [WissamZa](https://github.com/WissamZa)

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev/) — UI toolkit
- [sqflite](https://pub.dev/packages/sqflite) — SQLite plugin
- [fl_chart](https://pub.dev/packages/fl_chart) — Charts
- [Provider](https://pub.dev/packages/provider) — State management
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) — Icon generation
