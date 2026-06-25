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
- 🔬 **HbA1c Estimation** — calculated from 90-day average using the standard ADAG formula
- 📈 **Glucose Trends** — real-time trend arrows (rising fast ↑↑, rising ↑, stable →, falling ↓, falling fast ↓↓) with rate per hour
- 📅 **Weekly Summary** — readings count, weekly average, time-in-range percentage, high/low alerts
- 📌 **Measurement Patterns** — breakdown by reading type with averages

### Accessibility & Localization
- 🌐 **Bilingual UI** — Arabic (RTL) and English (LTR) with instant switching
- 🎨 **Three display themes** (switchable in settings):
  - **Classic Medical** (default) — clean teal/white, professional
  - **Modern Youth** — dark mode with vibrant gradients
  - **Elder Friendly** — large fonts, high contrast, thick borders
- 📏 **Dual unit support** — mg/dL and mmol/L with automatic conversion

### Data Management
- 💾 **Local SQLite storage** via sqflite — works fully offline
- 📤 **Export/Import** — JSON (full backup) and CSV (readings table) with share support
- 🔔 **Reminders** — schedule measurement reminders with quick toggle
- 🎯 **Customizable target range** — personalized min/max for in-range calculations
- 📱 **Native Android APK** — true native build (Dart → ARM/ARM64)

---

## 📱 Screens

| Screen | Purpose |
|--------|---------|
| 🚀 Onboarding | Choose language, theme, name, diabetes type (3 steps) |
| 🏠 Home | Latest reading hero card + trend arrow + HbA1c chip + daily stats + quick actions + recent readings |
| ➕ Add / Edit | Quick-add with ±10 buttons and presets; full edit mode |
| 📊 Chart | Area / line / bar charts + sort + full readings list with actions |
| 🔬 Insights | HbA1c estimation, glucose trends, weekly summary, measurement patterns |
| 📤 Export | JSON/CSV export & import with share functionality |
| 🔔 Reminders | Add / toggle / delete reminders with type + time |
| ⚙️ Settings | Language, theme, diabetes type, targets, units, profile, export |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | **Flutter 3.27+** (Material 3) |
| Language | **Dart 3.6+** |
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
- [Flutter SDK 3.27+](https://docs.flutter.dev/get-started/install)
- Android Studio (for SDK + emulator) OR command-line tools
- Java 17

> 🔐 `flutter_secure_storage` (used to store the SQLCipher DB key) relies on the **Android Keystore** on Android (requires `minSdkVersion` ≥ 18; this project uses 21) and the **iOS Keychain** on iOS — both available out of the box, no extra setup needed.

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
│   ├── models/
│   │   ├── reading.dart             # Reading + ReadingType + ReadingStatus
│   │   ├── reminder.dart            # Reminder
│   │   └── settings.dart            # Settings + Language + ThemeStyle + SortOrder
│   ├── database/
│   │   └── database_helper.dart     # SQLite (sqflite) — readings, reminders, settings
│   ├── providers/
│   │   └── providers.dart           # ReadingsProvider, RemindersProvider, SettingsProviderState
│   ├── i18n/
│   │   └── strings.dart             # AR + EN translations (~200 keys)
│   ├── themes/
│   │   └── app_theme.dart           # Classic / Modern / Elder color systems
│   ├── utils/
│   │   ├── unit_converter.dart      # mg/dL ↔ mmol/L conversion
│   │   ├── trend_analysis.dart      # Glucose trend calculation
│   │   ├── hba1c_calculator.dart    # HbA1c estimation via ADAG formula
│   │   └── export_import.dart       # JSON/CSV export & import
│   ├── screens/
│   │   ├── onboarding_screen.dart   # 3-step setup
│   │   ├── home_screen.dart         # Hero card + stats + trends + quick actions
│   │   ├── add_reading_screen.dart  # Dual-mode: add OR edit
│   │   ├── chart_screen.dart        # 3 chart types + sort + list
│   │   ├── insights_screen.dart     # HbA1c + trends + weekly summary + patterns
│   │   ├── export_screen.dart       # JSON/CSV export & import UI
│   │   ├── reminders_screen.dart    # Add / toggle / delete
│   │   └── settings_screen.dart     # Full settings UI + export shortcut
│   └── widgets/
│       └── reading_actions.dart     # Edit/Delete popup menu
├── android/                         # Android-specific config
├── assets/icons/                    # App icons
├── pubspec.yaml                     # Flutter dependencies
├── analysis_options.yaml
└── .github/workflows/apk-build.yml  # CI: build + release APK
```

---

## 📋 Database Schema

The app uses SQLite with 3 tables:

- **readings** — `id, value, type, timestamp, notes, carbs, insulin`
- **reminders** — `id, time, label, type, enabled`
- **settings** — singleton row with `language, theme, diabetes_type, target_min, target_max, unit, user_name, onboarded`

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
- 🔬 **تقدير HbA1c** — محسوب من متوسط 90 يوم باستخدام صيغة ADAG القياسية
- 📈 **اتجاهات السكر** — أسهم اتجاه في الوقت الفعلي (ارتفاع سريع ↑↑، في ارتفاع ↑، مستقر →، في انخفاض ↓، انخفاض سريع ↓↓) مع معدل بالساعة
- 📅 **الملخص الأسبوعي** — عدد القراءات، المتوسط الأسبوعي، نسبة الوقت في النطاق، تنبيهات مرتفعة/منخفضة
- 📌 **أنماط القياس** — تفصيل حسب نوع القراءة مع المتوسطات

### إمكانية الوصول والتخصيص
- 🌐 **واجهة ثنائية اللغة** — العربية (RTL) والإنجليزية (LTR) مع تبديل فوري
- 🎨 **ثلاثة أنماط عرض** (قابلة للتبديل في الإعدادات):
  - **الطبي الكلاسيكي** (افتراضي) — أنيق باللون الأخضر الفيروزي
  - **حديث شبابي** — الوضع الداكن بتدرجات نابضة
  - **ودود لكبار السن** — خطوط كبيرة، تباين عالٍ، حدود سميكة
- 📏 **دعم وحدتين** — ملغ/ديسيلتر ومليمول/لتر مع تحويل تلقائي

### إدارة البيانات
- 💾 **تخزين SQLite محلي** عبر sqflite — يعمل بالكامل بدون إنترنت
- 📤 **تصدير/استيراد** — JSON (نسخة احتياطية كاملة) و CSV (جدول القراءات) مع دعم المشاركة
- 🔔 **التذكيرات** — جدولة تذكيرات القياس مع تبديل سريع
- 🎯 **نطاق مستهدف قابل للتخصيص** — حد أدنى/أعلى مخصص لحسابات النطاق
- 📱 **APK أندرويد أصلي** — بناء أصلي حقيقي (Dart → ARM/ARM64)

---

## 📱 الشاشات

| الشاشة | الوظيفة |
|--------|---------|
| 🚀 الترحيب | اختيار اللغة، النمط، الاسم، نوع السكري (3 خطوات) |
| 🏠 الرئيسية | أحدث قراءة + سهم الاتجاه + شريط HbA1c + إحصائيات يومية + إجراءات سريعة + القراءات الأخيرة |
| ➕ إضافة / تعديل | إضافة سريعة بأزرار ±10 وقيم محددة؛ وضع تعديل كامل |
| 📊 الرسم البياني | 3 أنواع رسوم بيانية + ترتيب + قائمة القراءات كاملة |
| 🔬 التحليلات | تقدير HbA1c، اتجاهات السكر، الملخص الأسبوعي، أنماط القياس |
| 📤 التصدير | تصدير واستيراد JSON/CSV مع ميزة المشاركة |
| 🔔 التذكيرات | إضافة / تبديل / حذف التذكيرات مع النوع والوقت |
| ⚙️ الإعدادات | اللغة، النمط، نوع السكري، النطاق، الوحدات، الملف، التصدير |

---

## 🛠️ التقنيات المستخدمة

| الطبقة | التقنية |
|--------|---------|
| الإطار | **Flutter 3.27+** (Material 3) |
| اللغة | **Dart 3.6+** |
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
- [Flutter SDK 3.27+](https://docs.flutter.dev/get-started/install)
- Android Studio (لـ SDK + المحاكي) OR أدوات سطر الأوامر
- Java 17

> 🔐 `flutter_secure_storage` (المستخدمة لحفظ مفتاح تشفير SQLCipher) تعتمد على **Android Keystore** على أندرويد (تتطلب `minSdkVersion` ≥ 18؛ هذا المشروع يستخدم 21) و **iOS Keychain** على iOS — كلاهما متاح افتراضيًا دون إعداد إضافي.

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
│   ├── database/
│   │   └── database_helper.dart     # SQLite (sqflite)
│   ├── providers/
│   │   └── providers.dart           # ReadingsProvider, RemindersProvider, SettingsProviderState
│   ├── i18n/
│   │   └── strings.dart             # ترجمات AR + EN (~200 مفتاح)
│   ├── themes/
│   │   └── app_theme.dart           # أنظمة ألوان Classic / Modern / Elder
│   ├── utils/
│   │   ├── unit_converter.dart      # تحويل mg/dL ↔ mmol/L
│   │   ├── trend_analysis.dart      # حساب اتجاه السكر
│   │   ├── hba1c_calculator.dart    # تقدير HbA1c بصيغة ADAG
│   │   └── export_import.dart       # تصدير واستيراد JSON/CSV
│   ├── screens/
│   │   ├── onboarding_screen.dart   # إعداد 3 خطوات
│   │   ├── home_screen.dart         # بطاقة Hero + إحصائيات + اتجاهات + إجراءات سريعة
│   │   ├── add_reading_screen.dart  # الوضع المزدوج: إضافة أو تعديل
│   │   ├── chart_screen.dart        # 3 أنواع رسوم بيانية + ترتيب + قائمة
│   │   ├── insights_screen.dart     # HbA1c + اتجاهات + ملخص أسبوعي + أنماط
│   │   ├── export_screen.dart       # واجهة تصدير/استيراد JSON/CSV
│   │   ├── reminders_screen.dart    # إضافة / تبديل / حذف
│   │   └── settings_screen.dart     # إعدادات كاملة + اختصار تصدير
│   └── widgets/
│       └── reading_actions.dart     # قائمة منبثقة للتعديل/الحذف
├── android/                         # إعدادات أندرويد
├── assets/icons/                    # أيقونات التطبيق
├── pubspec.yaml                     # تبعيات Flutter
├── analysis_options.yaml
└── .github/workflows/apk-build.yml  # CI: بناء + إصدار APK
```

---

## 📋 مخطط قاعدة البيانات

يستخدم التطبيق SQLite مع 3 جداول:

- **readings** — `id, value, type, timestamp, notes, carbs, insulin`
- **reminders** — `id, time, label, type, enabled`
- **settings** — صف واحد يحتوي على `language, theme, diabetes_type, target_min, target_max, unit, user_name, onboarded`

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
