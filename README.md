# 🩸 GlucoTrack — سُكَّري

**Bilingual Blood Glucose Tracking App** — Arabic / English with three display themes, SQLite local storage, and optional Google Drive sync.

تطبيق ثنائي اللغة لمتابعة قياس السكر في الدم مع تخزين SQLite محلي ومزامنة اختيارية عبر Google Drive.

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

---

## 📦 Building for Production

### Web Build (Next.js static export)
```bash
bun run build
# Output goes to `out/` (static HTML/CSS/JS) — deployable to any static host
```

### APK Build (Android TWA)
The Android APK is built via **Bubblewrap** (Trusted Web Activity) — it wraps the deployed web app into a native Android shell. See [`.github/workflows/apk-build.yml`](.github/workflows/apk-build.yml) for full details.

**Quick start:**
1. Deploy the web app first (e.g. to GitHub Pages or Vercel)
2. Trigger the APK workflow manually with the deployed URL, OR push a tag `apk-v1.0.0`
3. Download the signed APK from the Releases page

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

### 📱 `apk-build.yml` — APK Build & Release
**Triggers:** Push tag `apk-v*` OR manual dispatch (with web URL)

**What it does:**
1. Sets up Java 17 + Android SDK + Bubblewrap CLI
2. Initializes a TWA project pointing at the deployed web app
3. Signs the APK with the keystore from repository secrets (or a debug keystore as fallback)
4. Creates a GitHub Release with the signed APK

**Required secrets** (Settings → Secrets and variables → Actions):
- `ANDROID_KEYSTORE_BASE64` — base64-encoded `.keystore` file
- `ANDROID_KEY_ALIAS` — key alias (e.g. `glucotrack`)
- `ANDROID_KEYSTORE_PASSWORD` — keystore password
- `ANDROID_KEY_PASSWORD` — key password

**Generating a signing keystore:**
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
├── prisma/
│   └── schema.prisma              # Reading, Reminder, Settings, SyncState
├── public/                        # Static assets
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
