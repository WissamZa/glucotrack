# 🩸 GlucoTrack — سُكَّري

**Bilingual Blood Glucose Tracking App** — Arabic / English with three display themes, SQLite local storage, and optional Google Drive sync.

تطبيق ثنائي اللغة لمتابعة قياس السكر في الدم مع تخزين SQLite محلي ومزامنة اختيارية عبر Google Drive.

> **Two implementations in this repo:**
> - **Web app** (`/` — Next.js 16 + Prisma + SQLite) — for browser/desktop
> - **Flutter app** (`/flutter_app` — Flutter 3.22 + sqflite) — for native Android APK
>
> Both share the same data model and JSON backup format, so data can be exchanged between them.

[![Web Build](https://github.com/WissamZa/glucotrack/actions/workflows/web-build.yml/badge.svg)](https://github.com/WissamZa/glucotrack/actions/workflows/web-build.yml)
[![APK Build](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml/badge.svg)](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## ✨ Features

### Core (MVP)
- 📝 **Log blood glucose readings** — value, type (fasting / before meal / after meal / before sleep / after exercise / other), timestamp, notes, carbs, insulin
- 📊 **Visualize trends** — line, area, and bar charts with target-range shading
- 🔔 **Reminders** — schedule measurement reminders with quick toggle

### Productivity
- ✏️ **Edit & delete readings** — full CRUD on every reading via the ⋮ menu
- 🔀 **Sort readings** — by newest, oldest, highest, lowest
- 🎯 **Customizable target range** — personalized min/max for in-range calculations
- 📈 **Statistics** — daily average, time-in-range (TIR), max, min, range, count

### Accessibility & Localization
- 🌐 **Bilingual UI** — Arabic (RTL) and English (LTR) with instant switching
- 🎨 **Three display themes** (switchable in settings):
  - **Classic Medical** (default) — clean teal/white, professional
  - **Modern Youth** — dark mode with vibrant gradients
  - **Elder Friendly** — large fonts, high contrast, thick borders

### Data & Sync
- 💾 **Local SQLite storage** via Prisma — works fully offline
- ☁️ **Optional Google Drive sync** — each user backs up to their own Drive
  - Uses `drive.appdata` scope (hidden, app-scoped folder — never touches user's other files)
  - Merge strategy: upsert by ID (remote wins on conflict, local settings preserved)
- 📤 **Local JSON backup** — export/import a full backup file (no internet needed)

### Phone-First Design
- 📱 Rendered inside a realistic phone frame for prototyping
- 🎯 Touch-optimized with 44px+ hit targets
- 🔄 Smooth animations via Framer Motion
- ♿ ARIA labels, semantic HTML, keyboard navigation

---

## 📱 Screens

| Screen | Purpose |
|--------|---------|
| 🚀 Onboarding | Choose language, theme, name, diabetes type (3 steps) |
| 🏠 Home | Latest reading hero card + daily stats + recent readings |
| ➕ Add / Edit | Quick-add with ±10 buttons and presets; full edit mode |
| 📈 Trends | Period-based stats + by-type distribution + readings list |
| 📊 Chart | Area / line / bar charts + sort + full readings list with actions |
| 🔔 Reminders | Add / toggle / delete reminders with type + time |
| ⚙️ Settings | Language, theme, diabetes type, targets, units, profile, sync |

---

## 🛠️ Tech Stack

### Web app (`/`)
| Layer | Technology |
|-------|------------|
| Framework | **Next.js 16** (App Router) |
| Language | **TypeScript 5** |
| Styling | **Tailwind CSS 4** + **shadcn/ui** |
| Database | **SQLite** via **Prisma ORM** |
| State | **Zustand** (UI) + **TanStack Query** (server cache) |
| Charts | **Recharts** |
| Animation | **Framer Motion** |
| Icons | **Lucide React** |
| Auth (Drive) | **Google Identity Services** (GIS) |
| Package Manager | **Bun** |

### Flutter app (`/flutter_app`)
| Layer | Technology |
|-------|------------|
| Framework | **Flutter 3.22** (Material 3) |
| Language | **Dart 3.4** |
| State | **Provider** |
| Database | **sqflite** (SQLite) — same schema as web app |
| Charts | **fl_chart** |
| Localization | **flutter_localizations** + custom AppStrings |
| Date formatting | **intl** |
| Icons | **flutter_launcher_icons** + Material Icons |

---

## 🚀 Getting Started

### Prerequisites
- Node.js 20+ and [Bun](https://bun.sh/)
- (Optional) A Google Cloud project with Drive API + OAuth 2.0 Client ID for sync

### Installation
```bash
# 1. Install dependencies
bun install

# 2. Configure environment
cp .env.example .env
# Edit .env and set DATABASE_URL (default is fine for local dev)
# Optionally set GOOGLE_CLIENT_ID for Drive sync

# 3. Initialize the database
bun run db:push

# 4. Start the dev server
bun run dev
# Open http://localhost:3000
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | SQLite path (e.g. `file:./db/custom.db`) |
| `GOOGLE_CLIENT_ID` | ❌ | OAuth 2.0 Client ID for Google Drive sync. Each end-user still signs in with **their own** Google account. |

### Flutter app (Android APK)

#### Prerequisites
- [Flutter SDK 3.22+](https://docs.flutter.dev/get-started/install)
- Android Studio (for SDK + emulator) OR command-line tools
- Java 17

#### Run in development
```bash
cd flutter_app
flutter pub get
flutter run                    # debug mode on connected device/emulator
```

#### Build APK locally
```bash
cd flutter_app
flutter build apk --release    # produces build/app/outputs/flutter-apk/app-release.apk
```

#### Database
The Flutter app uses **sqflite** with the same schema as the web app (Prisma). The DB file is created at:
- Android: `/data/data/com.wissamza.glucotrack/databases/glucotrack.db`

Data can be exchanged between the web and Flutter apps via the JSON backup format (see Settings → Local Backup in the web app).

---

## 📦 Building for Production

### Web Build (Next.js static export)
```bash
bun run build
# Output goes to `out/` (static HTML/CSS/JS) — deployable to any static host
```

### APK Build (Flutter — native Android)
The Android APK is built from the Flutter project in `/flutter_app` using the Flutter SDK + Gradle. This produces a **true native APK** (not a TWA wrapper) — Dart compiles to native ARM/ARM64 code.

**Quick start (local):**
```bash
cd flutter_app
flutter pub get
flutter run                  # debug mode on connected device
flutter build apk --release  # produces APK in build/app/outputs/flutter-apk/
```

**Via GitHub Actions:**
1. Push a tag `apk-v1.0.0` → triggers the workflow automatically
2. Or go to Actions → "APK Build & Release" → Run workflow
3. Download the signed APK from the Releases page

See [`.github/workflows/apk-build.yml`](.github/workflows/apk-build.yml) for full details on signing, secrets, and CI configuration.

---

## 🔧 GitHub Actions Workflows

This repo ships with two production-ready workflows:

### 🌐 `web-build.yml` — Web Build & Release
**Triggers:** Push tag `web-v*` OR manual dispatch

**What it does:**
1. Lints + builds the Next.js static export
2. Uploads build artifacts (static zip + standalone tarball)
3. Deploys to GitHub Pages (on tag push only)
4. Creates a GitHub Release with attached artifacts

```bash
# Trigger a release
git tag web-v1.0.0
git push origin web-v1.0.0
```

### 📱 `apk-build.yml` — APK Build & Release (Flutter)
**Triggers:** Push tag `apk-v*` OR manual dispatch

**What it does:**
1. Sets up Java 17 + Flutter SDK 3.22
2. Runs `flutter pub get` + `flutter analyze`
3. Configures signing keystore (production if secret set, debug otherwise)
4. Builds the APK with `flutter build apk --release`
5. Creates a GitHub Release with the signed APK attached

**Optional secrets** (Settings → Secrets and variables → Actions):
- `ANDROID_KEYSTORE_BASE64` — base64-encoded `.keystore` file (for Play Store)
- `ANDROID_KEY_ALIAS` — key alias
- `ANDROID_KEYSTORE_PASSWORD` — keystore password
- `ANDROID_KEY_PASSWORD` — key password

If secrets are not set, a debug keystore is auto-generated for testing.

**Generating a production signing keystore:**
```bash
keytool -genkey -v -keystore release.keystore -alias glucotrack \
  -keyalg RSA -keysize 2048 -validity 10000
# Then base64-encode it for the GitHub secret:
base64 -w 0 release.keystore
```

```bash
# Trigger a release
git tag apk-v1.0.0
git push origin apk-v1.0.0
```

---

## 📂 Project Structure

```
glucotrack/
├── flutter_app/                   # 📱 Native Android app (Flutter)
│   ├── lib/
│   │   ├── main.dart              # Entry point + providers + nav shell
│   │   ├── models/
│   │   │   ├── reading.dart       # Reading + ReadingType + ReadingStatus
│   │   │   ├── reminder.dart      # Reminder
│   │   │   └── settings.dart      # Settings + Language + ThemeStyle + ...
│   │   ├── database/
│   │   │   └── database_helper.dart  # SQLite (sqflite) — same schema as web
│   │   ├── providers/
│   │   │   └── providers.dart     # ReadingsProvider, RemindersProvider
│   │   ├── i18n/
│   │   │   └── strings.dart       # AR + EN translations
│   │   ├── themes/
│   │   │   └── app_theme.dart     # Classic / Modern / Elder themes
│   │   ├── screens/
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── add_reading_screen.dart  # Dual-mode: add OR edit
│   │   │   ├── chart_screen.dart        # 3 chart types + sort + list
│   │   │   ├── reminders_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       └── reading_actions.dart  # Edit/Delete popup menu
│   ├── android/                   # Android-specific config (Gradle, manifest)
│   ├── assets/icons/              # App icons
│   ├── pubspec.yaml               # Flutter dependencies
│   └── analysis_options.yaml
├── prisma/
│   └── schema.prisma              # Web app DB schema (matches Flutter schema)
├── public/                        # Web app static assets
├── src/
│   ├── app/
│   │   ├── api/                   # REST endpoints
│   │   │   ├── readings/[id]/     # GET/PATCH/DELETE
│   │   │   ├── readings/          # GET/POST
│   │   │   ├── reminders/[id]/    # PATCH/DELETE
│   │   │   ├── reminders/         # GET/POST
│   │   │   ├── settings/          # GET/PUT
│   │   │   ├── seed/              # POST (first-launch seeding)
│   │   │   └── sync/
│   │   │       ├── google-drive/  # POST (connect/upload/download/disconnect)
│   │   │       ├── status/        # GET
│   │   │       ├── config/        # GET
│   │   │       ├── local-export/  # GET (download JSON)
│   │   │       └── local-import/  # POST (merge JSON)
│   │   ├── layout.tsx
│   │   ├── page.tsx               # Main phone-frame shell + routing
│   │   └── globals.css
│   ├── components/
│   │   ├── phone/
│   │   │   ├── PhoneFrame.tsx     # Phone shell with notch
│   │   │   ├── BottomNav.tsx      # 5-tab navigation
│   │   │   └── ReadingActions.tsx # Edit/Delete menu per reading
│   │   ├── screens/
│   │   │   ├── Onboarding.tsx
│   │   │   ├── Home.tsx
│   │   │   ├── AddReading.tsx     # Dual-mode: add OR edit
│   │   │   ├── Trends.tsx
│   │   │   ├── Chart.tsx          # 3 chart types + sort
│   │   │   ├── Reminders.tsx
│   │   │   └── Settings.tsx       # Includes Drive sync UI
│   │   └── ui/                    # shadcn/ui components
│   ├── lib/
│   │   ├── types.ts               # Reading, Reminder, Settings, SortOrder, etc.
│   │   ├── i18n.ts                # Arabic + English translations
│   │   ├── themes.ts              # Classic / Modern / Elder color systems
│   │   ├── store.ts               # Zustand UI store + sortReadings helper
│   │   ├── api-hooks.ts           # TanStack Query hooks for all API calls
│   │   ├── google-drive.ts        # Drive upload/download/merge helpers
│   │   ├── db.ts                  # Prisma client
│   │   └── seed.ts                # Demo data for first launch
│   └── hooks/
│       └── use-toast.ts
├── .github/workflows/
│   ├── web-build.yml              # Next.js build + Pages deploy + Release
│   └── apk-build.yml              # Bubblewrap TWA APK + Release
├── prisma/schema.prisma
├── .env.example
├── package.json
└── README.md
```

---

## 🔐 Google Drive Sync — How It Works

Each user signs in with **their own** Google account. The `GOOGLE_CLIENT_ID` in `.env` only identifies the app to Google — it does **not** identify or restrict users.

```
┌─────────────────────────────────────────────────────────┐
│  User's browser                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  GlucoTrack web app                                │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  GIS token client                           │  │  │
│  │  │  → opens Google OAuth popup                 │  │  │
│  │  │  → user picks THEIR account                 │  │  │
│  │  │  → returns access token to app              │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────┬───────────────────────────┘  │
└──────────────────────────┼──────────────────────────────┘
                           │ POST /api/sync/google-drive
                           │   { action: "connect", accessToken: "..." }
                           ▼
┌─────────────────────────────────────────────────────────┐
│  GlucoTrack server (Next.js API)                         │
│  → stores token in local SQLite (SyncState table)        │
│  → uses token to upload/download backup JSON             │
└───────────────────────┬─────────────────────────────────┘
                        │ drive.file (appDataFolder scope)
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Google Drive — user's own account                       │
│  📁 appDataFolder/ (hidden, app-scoped)                  │
│  └── glucotrack-backup.json                              │
└─────────────────────────────────────────────────────────┘
```

The app **cannot** access any of the user's other Drive files — only the hidden `appDataFolder` reserved for this app.

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

- [Next.js](https://nextjs.org/) — React framework
- [Prisma](https://www.prisma.io/) — Type-safe ORM
- [shadcn/ui](https://ui.shadcn.com/) — Beautiful, accessible components
- [Recharts](https://recharts.org/) — Composable charts
- [Bubblewrap](https://github.com/GoogleChromeLabs/bubblewrap) — TWA tooling
- [Lucide](https://lucide.dev/) — Icon library
