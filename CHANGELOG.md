# Changelog

All notable changes to GlucoTrack are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/) — versions follow `MAJOR.MINOR.PATCH+build`.

## [1.9.2+13] — 2026-09-14

### Fixed — Nahdi product data (drug details)
- **Correct RSC response format**: the Nahdi search RSC stream returns simple product records (`sku`, `name`, `slug`, `price.{currency,value}`, `inStock`, `brand`, `image`, `rating`). The parser now handles this shape correctly in addition to the legacy Algolia shape, so price and in-stock status are reliably extracted.
- **Per-product detail lookup**: after the search, the service fetches each product's detail page via its `slug` and extracts **دواعي الاستخدام** (usage/indications), **الجرعة الموصى بها** (dosage), **طريقة الاستخدام** (method of use) and **المكونات الفعالة** (active ingredients). All fields are shown in the Nahdi card on the medication details screen.
- **Bundled Saudi drug details**: `SaudiDrug.toInfo()` now populates `indications` (from the Arabic `usage` line), `ingredients` and `otc` so the details screen correctly shows دواعي الاستخدام and OTC/Rx badge for all bundled Saudi drugs without requiring any network request.

## [1.9.1+12] — 2026-09-13

### Fixed — Nahdi product data extraction
- The v1.9.0 scanner cut records at every `"sku"` occurrence and missed most prices/usage lines (the page embeds multiple record shapes interleaved). Records are now extracted as **complete balanced-brace objects** with a string-aware scanner and decoded with a real JSON parser.
- Both price shapes are supported (`price.SAR.default` from the stream and `price.{currency,value}` from the grid payload), the top-level Arabic name and singular `ingredient` fields are read, and Algolia highlight markers are stripped everywhere.
- Verified against real captured payloads (both shapes) in the test suite.

## [1.9.0+11] — 2026-09-13

### Changed — add-reading FAB
- The FAB moved to the **side position (end)** and now appears **only on the Home tab**.

### Fixed & enriched — Nahdi drug data
- The Nahdi lookup previously returned prices for only a fraction of products. It now requests the site's data-stream endpoint (`_rsc`) and parses the **full product records**: Arabic + English names, price in SAR, **stock status**, product **image**, active ingredients, concentration, and **Arabic usage lines (طريقة الاستخدام)** — tolerant to both stream shapes, verified against real captured payloads.
- Details page: the Nahdi section now shows up to 3 product matches with image, price, in-stock badge, usage lines and ingredients.

### Added — dosage & method of use
- New fields on drug details: **الجرعة الموصى بها (dosage)** and **طريقة الاستخدام (method)**. openFDA entries populate them from the label's `dosage_and_administration` section; DB v8 (additive) caches them.

## [1.8.0+10] — 2026-09-13

### Fixed — tab bar
- The five-tab BottomAppBar with a notched center FAB was cramped/misaligned. The bar is now five evenly-spaced items and the add-reading FAB floats centered above it.

### Added — add medication from anywhere
- The reminder add/edit dialog is now a shared component: every drug in the Medications tab and the details page has an **"add reminder"** action that opens the dialog pre-filled with the drug's name, id and dose form.

### Added — full drug details + Nahdi price
- Details page now shows **active ingredients**, **indications (دواعي الاستخدام)** and a **prescription badge** (بوصفة / بدون وصفة):
  - Bundled Saudi entries carry curated Arabic usage lines and OTC/Rx flags.
  - openFDA entries pull the label's `indications_and_usage` and `active_ingredient` sections.
- **Nahdi Pharmacy price**: the details page fetches the product's approximate price from nahdionline.com and shows it (with a disclaimer). Prices are best-effort and hidden when unavailable. Cache columns added in DB v7 (additive).

## [1.7.0+9] — 2026-09-13

### Fixed — medication search
- Root cause: the RxNorm fuzzy-search endpoint returns many candidates **without a name**, which the parser dropped — plus Arabic queries could never match an English-only registry. Search now uses the rich `drugs.json` endpoint first, resolves nameless fuzzy candidates via `allProperties`, and the default source supports Arabic natively.

### Added — Medications tab & switchable drug sources
- New **Medications tab** (5th tab in the bottom bar): search any drug (Arabic or English), browse previously-looked-up entries and the user's own medication reminders, and open the full details page.
- **Switchable data sources** with a sensible default:
  - 🇸🇦 **Saudi (bundled, default)** — a built-in library of ~70 of the most common Saudi-market medications with Arabic + English names, searchable offline with Arabic normalization (أ/إ/آ and ة/ه variants match). No network, no registration.
  - 🌐 **International (RxNorm)** — the NLM registry, fixed as described above.
  - 🇺🇸 **US (openFDA)** — drug-label data (form, route, brand/generic).
  - The selection is persisted and applies everywhere (tab, reminder autocomplete, details page). The cache is now multi-source (DB v6: composite `(source, rxcui)` key; the old cache table holds disposable lookup data only, so it is recreated).

## [1.6.0+8] — 2026-09-13

### Fixed — medication reminder save
- Saving a reminder could silently fail when the notification scheduler threw (e.g. exact-alarm permission on Android 12+). Saving to the database now **always** succeeds; scheduling is best-effort with an automatic exact→inexact fallback, the exact-alarm permission is declared, and scheduling failures are logged instead of blocking the save.

### Added — smarter medication reminders
- Dose times are now divided across the **full 24 hours** (24h ÷ dose count: 2 → every 12h, 3 → every 8h, 4 → every 6h) anchored to the first dose time, wrapping past midnight when needed.
- **Structured dose**: a dropdown for the dose form (tablet / capsule / ml / drops / spray / cream / injection / insulin units) plus a numeric amount per dose, stored as data (DB v5, additive) instead of free text.
- **Medication autocomplete & details** via the free RxNorm API (U.S. National Library of Medicine — public domain, **no key or developer registration**): typing the name suggests matching drugs; picking one links the reminder to the drug and a new **Medication Details** page (from the reminder card or the dialog) shows name, synonym, dose form, strength and brand/generic type. Everything is cached in a local `medication_cache` table (30-day freshness) so repeat lookups work offline without re-requesting.

## [1.5.0+7] — 2026-09-13

### Added — one-tap medication schedule
- Choosing the number of doses per day (1–4) **auto-generates the remaining times** from the first dose time (evenly spread across the waking window, 6-hour max gap, snapped to 15 minutes — e.g. first 08:00 + 3 doses → 08:00 / 14:00 / 20:00). Every generated time stays individually editable; changing the count or the first dose re-seeds the schedule.

### Changed — cloud sync: WebDAV replaces Google Drive
- **Google Drive sync is disabled and removed** (it required developer-side OAuth registration). Replaced with **WebDAV sync**: the user connects their OWN server — self-hosted Nextcloud, Koofr, Synology, or any standard WebDAV host — so **no developer account at any provider is needed**.
- The backup is **encrypted on the phone before upload** (AES-256-GCM, key derived from a user passphrase via PBKDF2-HMAC-SHA256, 100k iterations): the server only ever stores ciphertext, and restore on another device just needs the same passphrase. Credentials live in the system secure storage (Android Keystore / iOS Keychain), never in the database.
- Available on **all platforms** (desktop included). See `docs/WEBDAV_SYNC.md`.
- Removed the `google_sign_in` dependency.

## [1.4.0+6] — 2026-09-12

### Added — medication scheduling & log (DB v4, additive migration)
- Medication reminders now support **days of the week** (7-day selector with localized names; presets like every day / weekend) and **multiple times per day** (e.g. 08:00 + 14:00 + 20:00). Notifications are scheduled per (day × time) using `dayOfWeekAndTime` matching; editing a schedule cancels the old pending notifications first.
- **Medication log**: a "Taken now" button on each medication card records the dose in a new `medication_log` table; the card shows "taken today N of M" progress and a history sheet lists every logged dose with date and time.
- Reminders are now **editable** — tap a card to change its schedule, name, or dose.

### Added — Google Drive backup sync (least privilege)
- Settings → Integrations replaces the "Coming soon" card with a working **Google Drive Sync**: sign in, one-tap **Sync now** (upload full JSON backup), and **Restore backup** (duplicate-safe merge).
- Requests **only** the `drive.appdata` scope — a hidden per-app folder the user's other apps (and the Drive UI) cannot see; GlucoTrack can never touch any other Drive file. Data moves directly phone ↔ Google, with no intermediary server. See `docs/DRIVE_SYNC_SETUP.md` for the one-time OAuth client setup.
- Available on Android & iOS; other platforms show the card as unsupported.

### Changed — UX
- The glucose value placeholder is now a **neutral semi-transparent gray** so it can no longer be mistaken for an entered value (the input style is large and bold).
- The **insulin dose field** in Add Reading is now hidden unless the user enables "I use insulin" in Settings (it always appears when editing a reading that already has a dose).
- Fixed pages being **cut off at the bottom**: scrollables in all tabs and pushed screens now clear the BottomAppBar and the system gesture inset (last cards are fully reachable).
- The center **add-reading FAB sits slightly lower** in the BottomAppBar notch.

### Data preservation (upgrade guarantee, unchanged)
- DB migration v3 → v4 is additive only (`days_mask`, `times`, `uses_insulin` columns + `medication_log` table). All pre-existing reminders default to "every day, existing single time" and keep firing exactly as before — covered by automated migration tests.

### Tests
- 178 total (up from 166): v3→v4 migration data-preservation, weekday-bit math, schedule round-trips, medication log, legacy-reminder defaults.

## [1.3.0+5] — 2026-09-12

### Data preservation (upgrade guarantee)
- Database migration v2 → v3 is **additive only** (new tables + nullable/defaulted columns). All readings, reminders and settings from v1.2.x survive untouched — covered by an automated migration test that recreates the old schema, seeds data, migrates, and verifies integrity.
- The SQLCipher database key stays in Android Keystore with the same algorithms; upgrading `flutter_secure_storage` 10 → 11 does **not** invalidate existing encrypted databases.
- Old JSON backups (pre-1.3) import unchanged; new backups add `healthMetrics` and `waterLog` keys that older app versions ignore.

### Added — patient features
- **Health Tips** (`/tips`): 51 bilingual (AR/EN) patient-education tips across 9 categories — nutrition, exercise, hypoglycemia (15-15 rule), hyperglycemia, foot care, medication & insulin, monitoring, mental wellbeing, and Ramadan fasting. Filterable by category chips, with a permanent medical disclaimer.
- **Tip of the Day** card on Home — deterministic per calendar day, taps through to the tips section.
- **Emergency guidance**: when a reading is critical (< 54, 54–69, or > 250 mg/dL) an actionable first-aid card appears on Home, and saving such a reading in Add Reading opens immediate step-by-step guidance (AR/EN) including "when to seek help".
- **Weight & blood-pressure tracking** (`/health`): new `health_metrics` table, add/delete entries (weight, systolic/diastolic), weight trend chart (fl_chart), latest-values summary and **BMI** card (WHO bands) using an optional height setting.
- **Water tracker**: daily cup counter with 8-cup goal, last-7-days mini chart on Home, new `water_log` table.
- **Medication reminders**: reminders now have a kind (glucose check / medication). Medication reminders use a dedicated Android notification channel (`glucotrack_medication`), and the add dialog collects medication name + dose.
- Insights screen: new general-health summary card (weight / BP / BMI) linking to `/health`.

### Added — quality & UX
- Settings now shows the **real app version** (via `package_info_plus`) instead of a hardcoded "1.1.0".
- **Measurement-unit toggle** in Settings (mg/dL ↔ mmol/L); the target-range fields are now unit-aware and re-render on switch.
- HbA1c card now shows the **category description** (already computed but previously unrendered).
- Tapping a reminder notification now deep-links to the Add Reading screen.
- Fourth quick-action button (Health Tips) on Home.

### Changed
- Flutter SDK constraint raised to ≥ 3.47.0 (built with 3.47.4 / Dart 3.13.3).
- Android **minSdk raised from 21 to 24** (Android 7.0+) — required by `flutter_secure_storage` 11.
- Dependencies upgraded to latest majors: `flutter_secure_storage` 11.1.1, `permission_handler` 13.0.2, `file_picker` 12.3.0 (stable, out of beta), plus minor bumps (`flutter_local_notifications` 22.3.0, `share_plus` 13.3.0, `flutter_blue_plus` 2.3.12, `sqflite_sqlcipher` 3.4.1, `intl` 0.20.3, `timezone` 0.11.1 …).
- `flutter pub upgrade --major-versions` applied; analyzer reports zero issues.

### Tests
- 49 new tests (117 → 166 total): DB v2→v3 migration with data preservation, tips dataset integrity (bilingual completeness, unique ids), emergency thresholds mirroring `Reading.status()`, BMI classification, water date keys, and backup backward compatibility.

## [1.2.5+4] — earlier history

See the git log and GitHub releases for versions prior to 1.3.0.
