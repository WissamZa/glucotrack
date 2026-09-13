<div align="center">

# 🩸 GlucoTrack — سُكَّري

**Bilingual Blood Glucose Tracking App** — Arabic / English with three display themes, comprehensive insights, and SQLite local storage.

**تطبيق ثنائي اللغة لمتابعة قياس السكر في الدم** — مع ثلاثة أنماط عرض وتحليلات شاملة وتخزين SQLite محلي.

[![APK Build](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml/badge.svg)](https://github.com/WissamZa/glucotrack/actions/workflows/apk-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.27+-blue.svg)](https://flutter.dev)

</div>

---

<!-- Language Toggle -->
<div align="center">

**[English](#english)** | **[العربية](#arabic)**

</div>

---

<a id="english"></a>
# 🇬🇧 English

## ✨ Features

### Core Tracking
- 📝 **Log blood glucose readings** — value, type (fasting / before meal / after meal / before sleep / after exercise / other), timestamp, notes, carbs, insulin
- ✏️ **Edit & delete readings** — full CRUD on every reading
- 📊 **Interactive charts** — area, line, and bar charts with target-range shading
- 🔀 **Sort readings** — by newest, oldest, highest, lowest

### Insights & Analysis
- 🔬 **HbA1c Estimation** — calculated from 90-day average using the standard ADAG formula, with category description
- 📈 **Glucose Trends** — real-time trend arrows (rising fast ↑↑, rising ↑, stable →, falling ↓, falling fast ↓↓) with rate per hour
- 📅 **Weekly Summary** — readings count, weekly average, time-in-range percentage, high/low alerts
- 📌 **Measurement Patterns** — breakdown by reading type with averages

### Patient Care (new in v1.3)
- 💡 **Health Tips** — 51 bilingual (AR/EN) patient-education tips in 9 categories: nutrition, exercise, hypoglycemia (15-15 rule), hyperglycemia, foot care, medication & insulin, monitoring, mental wellbeing, and Ramadan fasting
- ☀️ **Tip of the Day** — a fresh tip on the Home screen every day
- 🚨 **Emergency guidance** — actionable first-aid steps when a reading is critical (< 54, 54–69, or > 250 mg/dL), on Home and right after saving a critical reading
- ⚖️ **Weight & blood-pressure tracking** — entries with weight trend chart and BMI (WHO bands) from an optional height setting
- 💧 **Water tracker** — daily 8-cup goal with ± buttons and a last-7-days mini chart
- 💊 **Medication reminders** — days-of-week selector, doses auto-divided across 24 hours from the first dose time, structured dose (tablet / ml / drops… + amount), a "taken" log with history, and drug-name autocomplete + details — default source: a bundled Saudi-market library with offline Arabic search, switchable to RxNorm (international) or openFDA (US), all cached offline
- ☁️ **WebDAV backup** (optional) — connect your own server (Nextcloud, Koofr, Synology…), no developer registration, backup **encrypted on-device** (AES-256-GCM + PBKDF2 passphrase) before upload ([guide](docs/WEBDAV_SYNC.md))

### Accessibility & Localization
- 🌐 **Bilingual UI** — Arabic (RTL) and English (LTR) with instant switching
- 🎨 **Three display themes** (switchable in settings):
  - **Classic Medical** (default) — clean teal/white, professional
  - **Modern Youth** — dark mode with vibrant gradients
  - **Elder Friendly** — large fonts, high contrast, thick borders
- 📏 **Dual unit support** — mg/dL and mmol/L with automatic conversion and a unit toggle in Settings (target-range fields are unit-aware)

### Data Management
- 💾 **Local SQLite storage** via sqflite — works fully offline
- 📤 **Export/Import** — JSON (full backup, including weight/BP and water history) and CSV (readings table) with share support
- 🔔 **Reminders** — schedule measurement or medication reminders with quick toggle
- 🎯 **Customizable target range** — personalized min/max for in-range calculations
- 📱 **Native Android APK** — true native build (Dart → ARM/ARM64)

---

## 📱 Screens

| Screen | Purpose |
|--------|---------|
| 🚀 Onboarding | Choose language, theme, name, diabetes type (3 steps) |
| 🏠 Home | Latest reading hero card + trend arrow + HbA1c chip + daily stats + emergency guidance + water tracker + tip of the day + quick actions + recent readings |
| ➕ Add / Edit | Quick-add with ±10 buttons and presets; full edit mode; emergency guidance on critical saves |
| 📊 Chart | Area / line / bar charts + sort + full readings list with actions |
| 🔬 Insights | Health summary (weight/BP/BMI), HbA1c estimation, glucose trends, weekly summary, measurement patterns |
| 💡 Health Tips | 51 categorized patient-education tips (AR/EN) with medical disclaimer |
| ⚖️ Health | Weight & blood-pressure entries, BMI card, weight trend chart |
| 📤 Export | JSON/CSV export & import with share functionality |
| 🔔 Reminders | Add / toggle / delete glucose-check or medication reminders with time |
| ⚙️ Settings | Language, theme, units, diabetes type, targets, height, profile, export |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | **Flutter 3.47+** (Material 3) |
| Language | **Dart 3.13+** |
| State | **Provider** |
| Database | **sqflite_sqlcipher** (SQLite) |
| Charts | **fl_chart** |
| Localization | **flutter_localizations** + custom AppStrings |
| Notifications | **flutter_local_notifications** |
| Date formatting | **intl** |
| File I/O | **file_picker**, **share_plus**, **path_provider** |
| Icons | **flutter_launcher_icons** + Material Icons |

> 🔐 The database is encrypted at rest with **SQLCipher**. The encryption key is stored in the Android Keystore / iOS Keychain via `flutter_secure_storage`.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK 3.47+](https://docs.flutter.dev/get-started/install)
- Android Studio (for SDK + emulator) OR command-line tools
- Java 17

> 🔐 `flutter_secure_storage` (used to store the SQLCipher DB key) relies on the **Android Keystore** on Android and the **iOS Keychain** on iOS — both available out of the box, no extra setup needed.
> ⚠️ Since v1.3.0 the app requires **Android 7.0 (API 24)** or newer — a requirement of `flutter_secure_storage` v11.

### Run in development
```bash
flutter pub get
flutter run                    # debug mode on connected device/emulator
```

### Build APK locally

To build a "fat" APK containing all architectures (largest size):
```bash
flutter build apk --release
```

To build split APKs for each architecture (significantly smaller, recommended for direct distribution):
```bash
flutter build apk --release --split-per-abi
# produces build/app/outputs/flutter-apk/app-arm64-v8a-release.apk, etc.
```

To build an Android App Bundle (recommended for Google Play Store):
```bash
flutter build appbundle
# produces build/app/outputs/bundle/release/app-release.aab
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
git tag apk-v1.2.0
git push origin apk-v1.2.0

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
│   ├── data/
│   │   └── health_tips.dart         # 51 bilingual patient-education tips (9 categories)
│   ├── models/
│   │   ├── reading.dart             # Reading + ReadingType + ReadingStatus
│   │   ├── reminder.dart            # Reminder + ReminderKind (glucose/medication)
│   │   ├── health_metric.dart       # Weight/BP entry + BMI + WaterEntry
│   │   └── settings.dart            # Settings + Language + ThemeStyle + SortOrder
│   ├── database/
│   │   └── database_helper.dart     # SQLite/SQLCipher — v3 schema + additive migrations
│   ├── providers/
│   │   └── providers.dart           # Readings, Reminders, HealthMetrics + Settings providers
│   ├── i18n/
│   │   └── strings.dart             # AR + EN translations
│   ├── themes/
│   │   └── app_theme.dart           # Classic / Modern / Elder color systems
│   ├── utils/
│   │   ├── unit_converter.dart      # mg/dL ↔ mmol/L conversion
│   │   ├── trend_analysis.dart      # Glucose trend calculation
│   │   ├── hba1c_calculator.dart    # HbA1c estimation via ADAG formula
│   │   ├── emergency_guidance.dart  # First-aid guidance for critical readings
│   │   └── export_import.dart       # JSON/CSV export & import
│   ├── screens/
│   │   ├── onboarding_screen.dart   # 3-step setup
│   │   ├── home_screen.dart         # Hero card + stats + emergency + water + tip of the day
│   │   ├── add_reading_screen.dart  # Dual-mode: add OR edit
│   │   ├── chart_screen.dart        # 3 chart types + sort + list
│   │   ├── insights_screen.dart     # Health summary + HbA1c + trends + weekly + patterns
│   │   ├── tips_screen.dart         # Categorized health tips
│   │   ├── health_screen.dart       # Weight/BP tracking + BMI + weight chart
│   │   ├── export_screen.dart       # JSON/CSV export & import UI
│   │   ├── reminders_screen.dart    # Glucose-check & medication reminders
│   │   ├── ble_sync_screen.dart     # OneTouch meter BLE sync
│   │   └── settings_screen.dart     # Full settings UI + export shortcut
│   ├── services/
│   │   ├── notification_service.dart # Local notifications (2 channels) + tap deep-link
│   │   └── keystore_service.dart     # DB encryption key storage
│   └── widgets/
│       ├── reading_actions.dart      # Edit/Delete popup menu
│       └── emergency_guidance_dialog.dart # Shared first-aid dialog
├── android/                         # Android-specific config (minSdk 24)
├── assets/icons/                    # App icons
├── docs/BLE_PROTOCOL.md             # OneTouch BLE protocol spec
├── pubspec.yaml                     # Flutter dependencies
├── CHANGELOG.md                     # Release history
├── analysis_options.yaml
└── .github/workflows/apk-build.yml  # CI: build + release APK
```

---

## 📋 Database Schema

SQLite (SQLCipher-encrypted), schema **version 3** — migrations are additive only, so data from any previous version survives upgrades:

- **readings** — `id, value, type, timestamp, notes, carbs, insulin`
- **reminders** — `id, time, label, type, enabled, kind` (`kind`: `measurement` | `medication`, v3)
- **settings** — singleton row with `language, theme, diabetes_type, target_min, target_max, unit, user_name, onboarded, height_cm` (v3)
- **health_metrics** (v3) — `id, weight_kg, systolic, diastolic, timestamp`
- **water_log** (v3) — `date (yyyy-MM-dd), cups`

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
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — Local notifications
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) — Icon generation

---

<a id="arabic"></a>
# 🇸🇦 العربية

<div dir="rtl">

## ✨ الميزات

### التتبع الأساسي
- 📝 **تسجيل قراءات سكر الدم** — القيمة، النوع (صائم / قبل الأكل / بعد الأكل / قبل النوم / بعد الرياضة / أخرى)، الوقت، الملاحظات، الكربوهيدرات، الأنسولين
- ✏️ **تعديل وحذف القراءات** — إدارة كاملة لكل قراءة
- 📊 **رسوم بيانية تفاعلية** — منحنى، خطي، وأعمدة مع ظل النطاق المستهدف
- 🔀 **ترتيب القراءات** — حسب الأحدث، الأقدم، الأعلى، الأدنى

### التحليلات والرؤى
- 🔬 **تقدير HbA1c** — محسوب من متوسط 90 يوم باستخدام صيغة ADAG القياسية، مع وصف التصنيف
- 📈 **اتجاهات السكر** — أسهم اتجاه في الوقت الفعلي (ارتفاع سريع ↑↑، في ارتفاع ↑، مستقر →، في انخفاض ↓، انخفاض سريع ↓↓) مع معدل بالساعة
- 📅 **الملخص الأسبوعي** — عدد القراءات، المتوسط الأسبوعي، نسبة الوقت في النطاق، تنبيهات مرتفعة/منخفضة
- 📌 **أنماط القياس** — تفصيل حسب نوع القراءة مع المتوسطات

### رعاية المريض (جديد في v1.3)
- 💡 **نصائح صحية** — 51 نصيحة ثنائية اللغة (عربي/إنجليزي) في 9 فئات: التغذية، النشاط البدني، هبوط السكر (قاعدة 15-15)، ارتفاع السكر، العناية بالقدمين، الدواء والأنسولين، المراقبة والقياس، الصحة النفسية، وصيام رمضان
- ☀️ **نصيحة اليوم** — نصيحة جديدة كل يوم في الشاشة الرئيسية
- 🚨 **إرشادات الطوارئ** — خطوات إسعاف ذاتي عند القراءات الحرجة (أقل من 54، بين 54-69، أو أعلى من 250 ملغ/ديسيلتر) في الرئيسية وفور حفظ قراءة حرجة
- ⚖️ **متابعة الوزن والضغط** — قياسات مع رسم بياني لتطور الوزن ومؤشر كتلة الجسم BMI (بتصنيف WHO) من طول اختياري
- 💧 **عدّاد الماء** — هدف يومي 8 أكواب مع أزرار ± ورسوم مصغرة لآخر 7 أيام
- 💊 **تذكيرات الدواء** — محدد أيام الأسبوع، توزيع الجرعات تلقائياً على 24 ساعة من وقت الجرعة الأولى، جرعة منظمة (حبة/مل/قطرة… + الكمية)، سجل تناول بالتاريخ، وإكمال تلقائي لاسم الدواء بالعربية والإنجليزية مع صفحة تفاصيل — المصدر الافتراضي قاعدة سعودية مدمجة تعمل بلا إنترنت، وقابل للتبديل إلى RxNorm أو openFDA، وكلها مع كاش محلي
- ☁️ **نسخ احتياطي عبر WebDAV** (اختياري) — اربط خادمك الخاص (Nextcloud، Koofr، Synology…) بلا تسجيل مطوّر، والنسخة **مشفرة على الجهاز** قبل الرفع (AES-256-GCM + كلمة مرور) ([الدليل](docs/WEBDAV_SYNC.md))

### إمكانية الوصول والتخصيص
- 🌐 **واجهة ثنائية اللغة** — العربية (RTL) والإنجليزية (LTR) مع تبديل فوري
- 🎨 **ثلاثة أنماط عرض** (قابلة للتبديل في الإعدادات):
  - **الطبي الكلاسيكي** (افتراضي) — أنيق باللون الأخضر الفيروزي
  - **حديث شبابي** — الوضع الداكن بتدرجات نابضة
  - **ودود لكبار السن** — خطوط كبيرة، تباين عالٍ، حدود سميكة
- 📏 **دعم وحدتين** — ملغ/ديسيلتر ومليمول/لتر مع تحويل تلقائي ومبدّل وحدة في الإعدادات (حقول النطاق المستهدف تدرك الوحدة)

### إدارة البيانات
- 💾 **تخزين SQLite محلي** عبر sqflite — يعمل بالكامل بدون إنترنت
- 📤 **تصدير/استيراد** — JSON (نسخة احتياطية كاملة تشمل الوزن/الضغط وسجل الماء) و CSV (جدول القراءات) مع دعم المشاركة
- 🔔 **التذكيرات** — جدولة تذكيرات القياس أو الدواء مع تبديل سريع
- 🎯 **نطاق مستهدف قابل للتخصيص** — حد أدنى/أعلى مخصص لحسابات النطاق
- 📱 **APK أندرويد أصلي** — بناء أصلي حقيقي (Dart → ARM/ARM64)

---

## 📱 الشاشات

| الشاشة | الوظيفة |
|--------|---------|
| 🚀 الترحيب | اختيار اللغة، النمط، الاسم، نوع السكري (3 خطوات) |
| 🏠 الرئيسية | أحدث قراءة + سهم الاتجاه + شريط HbA1c + إحصائيات يومية + بطاقة الطوارئ + عدّاد الماء + نصيحة اليوم + إجراءات سريعة + القراءات الأخيرة |
| ➕ إضافة / تعديل | إضافة سريعة بأزرار ±10 وقيم محددة؛ وضع تعديل كامل؛ إرشادات طوارئ عند الحفظ الحرج |
| 📊 الرسم البياني | 3 أنواع رسوم بيانية + ترتيب + قائمة القراءات كاملة |
| 🔬 التحليلات | ملخص الصحة (وزن/ضغط/BMI)، تقدير HbA1c، اتجاهات السكر، الملخص الأسبوعي، أنماط القياس |
| 💡 النصائح | 51 نصيحة مصنفة (عربي/إنجليزي) مع إخلاء مسؤولية طبي |
| ⚖️ الصحة | قياسات الوزن والضغط، بطاقة BMI، رسم تطور الوزن |
| 📤 التصدير | تصدير واستيراد JSON/CSV مع ميزة المشاركة |
| 🔔 التذكيرات | إضافة / تبديل / حذف تذكيرات القياس أو الدواء مع الوقت |
| ⚙️ الإعدادات | اللغة، النمط، الوحدات، نوع السكري، النطاق، الطول، الملف، التصدير |

---

## 🛠️ التقنيات المستخدمة

| الطبقة | التقنية |
|--------|---------|
| الإطار | **Flutter 3.47+** (Material 3) |
| اللغة | **Dart 3.13+** |
| إدارة الحالة | **Provider** |
| قاعدة البيانات | **sqflite_sqlcipher** (SQLite) |
| الرسوم البيانية | **fl_chart** |
| التعريب | **flutter_localizations** + AppStrings مخصص |
| الإشعارات | **flutter_local_notifications** |
| تنسيق التاريخ | **intl** |
| ملفات I/O | **file_picker**, **share_plus**, **path_provider** |
| الأيقونات | **flutter_launcher_icons** + Material Icons |

> 🔐 قاعدة البيانات مشفّرة عند التخزين باستخدام **SQLCipher**. مفتاح التشفير محفوظ في Android Keystore / iOS Keychain عبر `flutter_secure_storage`.

---

## 🚀 البدء

### المتطلبات
- [Flutter SDK 3.47+](https://docs.flutter.dev/get-started/install)
- Android Studio (لـ SDK + المحاكي) OR أدوات سطر الأوامر
- Java 17

> 🔐 `flutter_secure_storage` (المستخدمة لحفظ مفتاح تشفير SQLCipher) تعتمد على **Android Keystore** على أندرويد و **iOS Keychain** على iOS — كلاهما متاح افتراضيًا دون إعداد إضافي.
> ⚠️ منذ الإصدار v1.3.0 يتطلب التطبيق **أندرويد 7.0 (API 24)** أو أحدث — وهو شرط من `flutter_secure_storage` الإصدار 11.

### التشغيل في وضع التطوير
```bash
flutter pub get
flutter run                    # وضع التصحيح على الجهاز/المحاكي
```

### بناء APK محليًا
```bash
flutter build apk --release    # ينشئ build/app/outputs/flutter-apk/app-release.apk
```

### توليد أيقونات التطبيق
```bash
flutter pub run flutter_launcher_icons
```

---

## 📦 البناء عبر GitHub Actions

يتم بناء APK تلقائيًا بواسطة GitHub Actions عند دفع tag أو التشغيل اليدوي.

### تشغيل إصدار
```bash
# الخيار 1: دفع tag
git tag apk-v1.2.0
git push origin apk-v1.2.0

# الخيار 2: التشغيل اليدوي
# اذهب إلى Actions → "📱 APK Build & Release (Flutter)" → Run workflow
```

### توقيع الإنتاج (اختياري)
أضف هذه الأسرار (Settings → Secrets and variables → Actions):
- `ANDROID_KEYSTORE_BASE64` — ملف `.keystore` بترميز base64
- `ANDROID_KEY_ALIAS` — alias المفتاح (مثلاً `glucotrack`)
- `ANDROID_KEYSTORE_PASSWORD` — كلمة مرور keystore
- `ANDROID_KEY_PASSWORD` — كلمة مرور المفتاح

**توليد keystore للتوقيع:**
```bash
keytool -genkey -v -keystore release.keystore -alias glucotrack \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w 0 release.keystore
```

إذا لم يتم تعيين الأسرار، يتم توليد debug keystore تلقائيًا للاختبار.

---

## 📂 هيكل المشروع

```
glucotrack/
├── lib/
│   ├── main.dart                    # نقطة الدخول + providers + شريط التنقل
│   ├── models/
│   │   ├── reading.dart             # Reading + ReadingType + ReadingStatus
│   │   ├── reminder.dart            # Reminder
│   │   └── settings.dart            # Settings + Language + ThemeStyle + SortOrder
│   ├── data/
│   │   └── health_tips.dart         # 51 نصيحة صحية ثنائية اللغة (9 فئات)
│   ├── database/
│   │   └── database_helper.dart     # SQLite/SQLCipher — مخطط v3 + ترحيلات إضافية
│   ├── models/
│   │   ├── health_metric.dart       # الوزن/الضغط + BMI + سجل الماء
│   │   └── reminder.dart            # Reminder + ReminderKind (قياس/دواء)
│   ├── providers/
│   │   └── providers.dart           # مزودات القراءات والتذكيرات والمقاييس الصحية والإعدادات
│   ├── i18n/
│   │   └── strings.dart             # ترجمات AR + EN
│   ├── themes/
│   │   └── app_theme.dart           # أنظمة ألوان Classic / Modern / Elder
│   ├── utils/
│   │   ├── unit_converter.dart      # تحويل mg/dL ↔ mmol/L
│   │   ├── trend_analysis.dart      # حساب اتجاه السكر
│   │   ├── hba1c_calculator.dart    # تقدير HbA1c بصيغة ADAG
│   │   ├── emergency_guidance.dart  # إرشادات الإسعاف للقراءات الحرجة
│   │   └── export_import.dart       # تصدير واستيراد JSON/CSV
│   ├── screens/
│   │   ├── onboarding_screen.dart   # إعداد 3 خطوات
│   │   ├── home_screen.dart         # Hero + إحصائيات + طوارئ + ماء + نصيحة اليوم
│   │   ├── add_reading_screen.dart  # الوضع المزدوج: إضافة أو تعديل
│   │   ├── chart_screen.dart        # 3 أنواع رسوم بيانية + ترتيب + قائمة
│   │   ├── insights_screen.dart     # ملخص الصحة + HbA1c + اتجاهات + ملخص أسبوعي
│   │   ├── tips_screen.dart         # النصائح الصحية المصنفة
│   │   ├── health_screen.dart       # متابعة الوزن/الضغط + BMI + رسم الوزن
│   │   ├── export_screen.dart       # واجهة تصدير/استيراد JSON/CSV
│   │   ├── reminders_screen.dart    # تذكيرات القياس والدواء
│   │   └── settings_screen.dart     # إعدادات كاملة + اختصار تصدير
│   ├── services/
│   │   ├── notification_service.dart # إشعارات محلية (قناتان) + رابط عميق عند النقر
│   │   └── keystore_service.dart     # تخزين مفتاح تشفير قاعدة البيانات
│   └── widgets/
│       ├── reading_actions.dart     # قائمة منبثقة للتعديل/الحذف
│       └── emergency_guidance_dialog.dart # حوار الإسعاف المشترك
├── android/                         # إعدادات أندرويد (minSdk 24)
├── assets/icons/                    # أيقونات التطبيق
├── docs/BLE_PROTOCOL.md             # مواصفة بروتوكول BLE لأجهزة OneTouch
├── pubspec.yaml                     # تبعيات Flutter
├── CHANGELOG.md                     # سجل الإصدارات
├── analysis_options.yaml
└── .github/workflows/apk-build.yml  # CI: بناء + إصدار APK
```

---

## 📋 مخطط قاعدة البيانات

SQLite (مشفرة SQLCipher)، إصدار المخطط **3** — الترحيلات إضافية فقط، لذا تبقى بيانات أي نسخة سابقة سليمة عند الترقية:

- **readings** — `id, value, type, timestamp, notes, carbs, insulin`
- **reminders** — `id, time, label, type, enabled, kind` (`kind`: قياس أو دواء، v3)
- **settings** — صف واحد يحتوي على `language, theme, diabetes_type, target_min, target_max, unit, user_name, onboarded, height_cm` (v3)
- **health_metrics** (v3) — `id, weight_kg, systolic, diastolic, timestamp`
- **water_log** (v3) — `date (yyyy-MM-dd), cups`

موقع ملف قاعدة البيانات على أندرويد:
`/data/data/com.wissamza.glucotrack/databases/glucotrack.db`

---

## 🤝 المساهمة

1. Fork المستودع
2. أنشئ فرع الميزة (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push إلى الفرع (`git push origin feature/amazing-feature`)
5. افتح Pull Request

---

## 📜 الترخيص

MIT © [WissamZa](https://github.com/WissamZa)

---

## 🙏 شكر وتقدير

- [Flutter](https://flutter.dev/) — أدوات واجهة المستخدم
- [sqflite](https://pub.dev/packages/sqflite) — إضافة SQLite
- [fl_chart](https://pub.dev/packages/fl_chart) — الرسوم البيانية
- [Provider](https://pub.dev/packages/provider) — إدارة الحالة
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — الإشعارات المحلية
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) — توليد الأيقونات

</div>
