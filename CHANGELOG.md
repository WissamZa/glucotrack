# Changelog

All notable changes to GlucoTrack are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/) — versions follow `MAJOR.MINOR.PATCH+build`.

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
