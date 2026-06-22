// App strings + SettingsProvider state.
//
// This file combines translations (AR/EN) with the SettingsProvider
// state management class to avoid circular imports.
import 'package:flutter/material.dart';
import '../models/reading.dart';
import '../models/settings.dart';

// ===== Settings Provider =====
class SettingsProviderState extends ChangeNotifier {
  Settings _settings = const Settings();
  Settings get settings => _settings;

  void update(Settings s) {
    _settings = s;
    notifyListeners();
  }
}

class SettingsInherited extends InheritedWidget {
  final SettingsProviderState data;
  const SettingsInherited({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(SettingsInherited old) =>
      old.data.settings != data.settings;
}

// Static accessor (used in AppStrings.of)
SettingsProviderState _lookupSettingsProvider(BuildContext context) {
  final inh = context.dependOnInheritedWidgetOfExactType<SettingsInherited>();
  if (inh == null) {
    throw FlutterError('SettingsProvider not found in widget tree');
  }
  return inh.data;
}

// ===== Strings =====
class AppStrings {
  final Language lang;
  AppStrings(this.lang);

  static AppStrings of(BuildContext context) {
    final lang = _lookupSettingsProvider(context).settings.language;
    return AppStrings(lang);
  }

  String get(String key) {
    final dict = lang == Language.ar ? _ar : _en;
    return dict[key] ?? key;
  }

  // Shorthand getters for common strings
  String get appName => get('app_name');
  String get appTagline => get('app_tagline');
  String get navHome => get('nav_home');
  String get navChart => get('nav_chart');
  String get navAdd => get('nav_add');
  String get navReminders => get('nav_reminders');
  String get navSettings => get('nav_settings');
  String get save => get('save');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get edit => get('edit');
  String get ok => get('ok');
  String get close => get('close');
  String get back => get('back');
  String get welcome => get('welcome');
  String get chooseLanguage => get('choose_language');
  String get chooseStyle => get('choose_style');
  String get styleClassic => get('style_classic');
  String get styleClassicDesc => get('style_classic_desc');
  String get styleModern => get('style_modern');
  String get styleModernDesc => get('style_modern_desc');
  String get styleElder => get('style_elder');
  String get styleElderDesc => get('style_elder_desc');
  String get getStarted => get('get_started');
  String get yourName => get('your_name');
  String get yourDiabetesType => get('your_diabetes_type');
  String get language => get('language');
  String get displayStyle => get('display_style');
  String get diabetesType => get('diabetes_type');
  String get diabetesType1 => get('diabetes_type1');
  String get diabetesType2 => get('diabetes_type2');
  String get diabetesGestational => get('diabetes_gestational');
  String get targetMin => get('target_min');
  String get targetMax => get('target_max');
  String get name => get('name');
  String get addReading => get('add_reading');
  String get editReading => get('edit_reading');
  String get glucoseValue => get('glucose_value');
  String get measurementType => get('measurement_type');
  String get time => get('time');
  String get notes => get('notes');
  String get notesPlaceholder => get('notes_placeholder');
  String get carbsGrams => get('carbs_grams');
  String get insulinUnits => get('insulin_units');
  String get savedSuccess => get('saved_success');
  String get editedSuccess => get('edited_success');
  bool get isRtl => lang.isRtl;
  String get invalidValue => get('invalid_value');
  String get deleteReading => get('delete_reading');
  String get deleteConfirm => get('delete_confirm');
  String get chart => get('chart');
  String get glucoseChart => get('glucose_chart');
  String get statReadings => get('stat_readings');
  String get statInRange => get('stat_in_range');
  String get statAvg => get('stat_avg');
  String get statMin => get('stat_min');
  String get statMax => get('stat_max');
  String get noDataPeriod => get('no_data_period');
  String get sortBy => get('sort_by');
  String get sortNewest => get('sort_newest');
  String get sortOldest => get('sort_oldest');
  String get sortHighest => get('sort_highest');
  String get sortLowest => get('sort_lowest');
  String get recentReadings => get('recent_readings');
  String get viewAll => get('view_all');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get latestReading => get('latest_reading');
  String get avgToday => get('avg_today');
  String get readingsCount => get('readings_count');
  String get inRangePct => get('in_range_pct');
  String get noReadingsYet => get('no_readings_yet');
  String get addFirstReading => get('add_first_reading');
  String get statusLow => get('status_low');
  String get statusInRange => get('status_in_range');
  String get statusHigh => get('status_high');
  String get statusCriticalLow => get('status_critical_low');
  String get statusCriticalHigh => get('status_critical_high');
  String get reminders => get('reminders');
  String get addReminder => get('add_reminder');
  String get reminderTime => get('reminder_time');
  String get reminderLabel => get('reminder_label');
  String get noReminders => get('no_reminders');
  String get reminderAdded => get('reminder_added');
  String get reminderDeleted => get('reminder_deleted');
  String get settings => get('settings');
  String get appearance => get('appearance');
  String get health => get('health');
  String get glucoseTargets => get('glucose_targets');
  String get glucoseUnit => get('glucose_unit');
  String get unitMg => get('unit_mg');
  String get unitMmol => get('unit_mmol');
  String get profile => get('profile');
  String get integrations => get('integrations');
  String get deviceIntegration => get('device_integration');
  String get comingSoon => get('coming_soon');
  String get comingSoonDesc => get('coming_soon_desc');
  String get about => get('about');
  String get version => get('version');
  String get resetData => get('reset_data');
  String get resetConfirm => get('reset_confirm');
  String get resetDone => get('reset_done');
  String get saveSettings => get('save_settings');
  String get loading => get('loading');
  String get periodToday => get('period_today');
  String get periodWeek => get('period_week');
  String get periodMonth => get('period_month');
  String get goodMorning => get('good_morning');
  String get goodAfternoon => get('good_afternoon');
  String get goodEvening => get('good_evening');
  String get goodNight => get('good_night');
  // New feature strings
  String get searchHint => get('search_hint');
  String get searchByValue => get('search_by_value');
  String get searchByType => get('search_by_type');
  String get searchByNotes => get('search_by_notes');
  String get filterAllTypes => get('filter_all_types');
  String get noSearchResults => get('no_search_results');
  String get trendLabel => get('trend_label');
  String get trendRisingFast => get('trend_rising_fast');
  String get trendRising => get('trend_rising');
  String get trendStable => get('trend_stable');
  String get trendFalling => get('trend_falling');
  String get trendFallingFast => get('trend_falling_fast');
  String get hba1cTitle => get('hba1c_title');
  String get hba1cEstimate => get('hba1c_estimate');
  String get hba1cAverage => get('hba1c_average');
  String get hba1cNormal => get('hba1c_normal');
  String get hba1cPrediabetes => get('hba1c_prediabetes');
  String get hba1cDiabetes => get('hba1c_diabetes');
  String get hba1cNoData => get('hba1c_no_data');
  String get weeklySummary => get('weekly_summary');
  String get thisWeek => get('this_week');
  String get lastWeek => get('last_week');
  String get readingsThisWeek => get('readings_this_week');
  String get avgThisWeek => get('avg_this_week');
  String get timeInRangeWeek => get('time_in_range_week');
  String get highReadings => get('high_readings');
  String get lowReadings => get('low_readings');
  String get noReadingsThisWeek => get('no_readings_this_week');
  String get exportData => get('export_data');
  String get importData => get('import_data');
  String get exportJson => get('export_json');
  String get exportCsv => get('export_csv');
  String get shareBackup => get('share_backup');
  String importSuccess(int count) => get('import_success').replaceAll('{count}', '$count');
  String get importError => get('import_error');
  String get exportSuccess => get('export_success');
  String get medicationLog => get('medication_log');
  String get addMedication => get('add_medication');
  String get medicationName => get('medication_name');
  String get medicationDose => get('medication_dose');
  String get medicationTime => get('medication_time');
  String get insulinLog => get('insulin_log');
  String get totalInsulinToday => get('total_insulin_today');
  String get insulinUnitsShort => get('insulin_units_short');
  String get notificationSettings => get('notification_settings');
  String get enableNotifications => get('enable_notifications');
  String get reminderNotification => get('reminder_notification');
  String get unitMmolLFull => get('unit_mmol_l_full');
  String get insights => get('insights');
  String get glucoseInsights => get('glucose_insights');
  String get noTrendData => get('no_trend_data');

  String readingType(ReadingType t) {
    switch (t) {
      case ReadingType.fasting:
        return get('type_fasting');
      case ReadingType.beforeMeal:
        return get('type_before_meal');
      case ReadingType.afterMeal:
        return get('type_after_meal');
      case ReadingType.beforeSleep:
        return get('type_before_sleep');
      case ReadingType.afterExercise:
        return get('type_after_exercise');
      case ReadingType.other:
        return get('type_other');
    }
  }

  String statusLabel(ReadingStatus s) {
    switch (s) {
      case ReadingStatus.low:
        return get('status_low');
      case ReadingStatus.inRange:
        return get('status_in_range');
      case ReadingStatus.high:
        return get('status_high');
      case ReadingStatus.criticalLow:
        return get('status_critical_low');
      case ReadingStatus.criticalHigh:
        return get('status_critical_high');
    }
  }
}

// ===== Translation dictionaries =====
const Map<String, String> _ar = {
  'app_name': 'سُكَّري',
  'app_tagline': 'تابع سكرك بصحة وثقة',
  'nav_home': 'الرئيسية',
  'nav_chart': 'الرسم',
  'nav_add': 'إضافة',
  'nav_reminders': 'التذكيرات',
  'nav_settings': 'الإعدادات',
  'save': 'حفظ',
  'cancel': 'إلغاء',
  'delete': 'حذف',
  'edit': 'تعديل',
  'ok': 'حسناً',
  'close': 'إغلاق',
  'back': 'رجوع',
  'welcome': 'مرحباً بك',
  'choose_language': 'اختر اللغة',
  'choose_style': 'اختر نمط العرض',
  'style_classic': 'الطبي الكلاسيكي',
  'style_classic_desc': 'أنيق ومهني بألوان هادئة',
  'style_modern': 'حديث شبابي',
  'style_modern_desc': 'تصميم عصري بألوان نابضة',
  'style_elder': 'ودود لكبار السن',
  'style_elder_desc': 'خطوط كبيرة وتباين عالٍ',
  'get_started': 'ابدأ الآن',
  'your_name': 'اسمك',
  'your_diabetes_type': 'نوع السكري لديك',
  'diabetes_type1': 'النوع الأول',
  'diabetes_type2': 'النوع الثاني',
  'diabetes_gestational': 'سكر الحمل',
  'good_morning': 'صباح الخير',
  'good_afternoon': 'مساء الخير',
  'good_evening': 'مساء الخير',
  'good_night': 'طاب ليلك',
  'latest_reading': 'آخر قراءة',
  'avg_today': 'المتوسط اليومي',
  'readings_count': 'عدد القراءات',
  'in_range_pct': 'نسبة الوقت في النطاق',
  'no_readings_yet': 'لا توجد قراءات بعد',
  'add_first_reading': 'أضف قراءتك الأولى الآن',
  'recent_readings': 'أحدث القراءات',
  'view_all': 'عرض الكل',
  'today': 'اليوم',
  'yesterday': 'أمس',
  'type_fasting': 'صائم',
  'type_before_meal': 'قبل الأكل',
  'type_after_meal': 'بعد الأكل',
  'type_before_sleep': 'قبل النوم',
  'type_after_exercise': 'بعد الرياضة',
  'type_other': 'أخرى',
  'status_low': 'منخفض',
  'status_in_range': 'ضمن النطاق',
  'status_high': 'مرتفع',
  'status_critical_low': 'حرج منخفض',
  'status_critical_high': 'حرج مرتفع',
  'add_reading': 'إضافة قراءة جديدة',
  'edit_reading': 'تعديل القراءة',
  'glucose_value': 'قيمة السكر',
  'measurement_type': 'نوع القياس',
  'time': 'الوقت',
  'notes': 'ملاحظات',
  'notes_placeholder': 'أضف ملاحظة (اختياري)',
  'carbs_grams': 'الكربوهيدرات (غرام)',
  'insulin_units': 'الأنسولين (وحدة)',
  'saved_success': 'تم حفظ القراءة بنجاح',
  'edited_success': 'تم تحديث القراءة بنجاح',
  'deleted_success': 'تم حذف القراءة',
  'invalid_value': 'أدخل قيمة صحيحة (20-600)',
  'delete_confirm': 'هل تريد حذف هذه القراءة؟',
  'delete_reading': 'حذف القراءة',
  'chart': 'الرسم البياني',
  'period_today': 'اليوم',
  'period_week': 'الأسبوع',
  'period_month': 'الشهر',
  'glucose_chart': 'منحنى السكر',
  'stat_avg': 'المتوسط',
  'stat_max': 'الأعلى',
  'stat_min': 'الأدنى',
  'stat_readings': 'القراءات',
  'stat_in_range': 'في النطاق',
  'no_data_period': 'لا توجد بيانات في هذه الفترة',
  'sort_by': 'ترتيب حسب',
  'sort_newest': 'الأحدث',
  'sort_oldest': 'الأقدم',
  'sort_highest': 'الأعلى',
  'sort_lowest': 'الأدنى',
  'reminders': 'التذكيرات',
  'add_reminder': 'إضافة تذكير',
  'reminder_time': 'الوقت',
  'reminder_label': 'الوصف',
  'no_reminders': 'لا توجد تذكيرات بعد',
  'reminder_added': 'تم إضافة التذكير',
  'reminder_deleted': 'تم حذف التذكير',
  'settings': 'الإعدادات',
  'appearance': 'المظهر',
  'language': 'اللغة',
  'display_style': 'نمط العرض',
  'health': 'الصحة',
  'diabetes_type': 'نوع السكري',
  'glucose_targets': 'النطاق المستهدف',
  'target_min': 'الحد الأدنى',
  'target_max': 'الحد الأعلى',
  'glucose_unit': 'وحدة القياس',
  'unit_mg': 'ملغ/ديسيلتر',
  'unit_mmol': 'مليمول/لتر',
  'profile': 'الملف الشخصي',
  'name': 'الاسم',
  'integrations': 'التكاملات',
  'device_integration': 'ربط الأجهزة',
  'coming_soon': 'قيد التطوير',
  'coming_soon_desc': 'سنضيف دعم أجهزة Accu-Chek و FreeStyle Libre قريباً',
  'about': 'حول التطبيق',
  'version': 'الإصدار',
  'reset_data': 'إعادة تعيين البيانات',
  'reset_confirm': 'هل أنت متأكد من حذف جميع البيانات؟',
  'reset_done': 'تمت إعادة التعيين',
  'save_settings': 'تم حفظ الإعدادات',
  'loading': 'جارٍ التحميل...',
  // New feature translations - Arabic
  'search_hint': 'ابحث في القراءات...',
  'search_by_value': 'القيمة',
  'search_by_type': 'النوع',
  'search_by_notes': 'الملاحظات',
  'filter_all_types': 'جميع الأنواع',
  'no_search_results': 'لا توجد نتائج مطابقة',
  'trend_label': 'الاتجاه',
  'trend_rising_fast': 'ارتفاع سريع',
  'trend_rising': 'في ارتفاع',
  'trend_stable': 'مستقر',
  'trend_falling': 'في انخفاض',
  'trend_falling_fast': 'انخفاض سريع',
  'hba1c_title': 'تقدير HbA1c',
  'hba1c_estimate': 'نسبة HbA1c المقدرة',
  'hba1c_average': 'متوسط السكر التقديري',
  'hba1c_normal': 'طبيعي',
  'hba1c_prediabetes': 'ما قبل السكري',
  'hba1c_diabetes': 'نطاق السكري',
  'hba1c_no_data': 'لا توجد بيانات كافية لتقدير HbA1c',
  'weekly_summary': 'الملخص الأسبوعي',
  'this_week': 'هذا الأسبوع',
  'last_week': 'الأسبوع الماضي',
  'readings_this_week': 'القراءات هذا الأسبوع',
  'avg_this_week': 'المتوسط الأسبوعي',
  'time_in_range_week': 'الوقت في النطاق',
  'high_readings': 'القراءات المرتفعة',
  'low_readings': 'القراءات المنخفضة',
  'no_readings_this_week': 'لا توجد قراءات هذا الأسبوع',
  'export_data': 'تصدير البيانات',
  'import_data': 'استيراد البيانات',
  'export_json': 'تصدير JSON',
  'export_csv': 'تصدير CSV',
  'share_backup': 'مشاركة النسخة الاحتياطية',
  'import_success': 'تم استيراد {count} قراءة بنجاح',
  'import_error': 'فشل استيراد الملف. تنسيق غير صالح.',
  'export_success': 'تم تصدير البيانات بنجاح',
  'medication_log': 'سجل الأدوية',
  'add_medication': 'إضافة دواء',
  'medication_name': 'اسم الدواء',
  'medication_dose': 'الجرعة',
  'medication_time': 'وقت الدواء',
  'insulin_log': 'سجل الأنسولين',
  'total_insulin_today': 'إجمالي الأنسولين اليوم',
  'insulin_units_short': 'وحدة',
  'notification_settings': 'إعدادات الإشعارات',
  'enable_notifications': 'تفعيل الإشعارات',
  'reminder_notification': 'تذكير بقياس السكر',
  'unit_mmol_l_full': 'mmol/L',
  'insights': 'تحليلات',
  'glucose_insights': 'تحليلات السكر',
  'no_trend_data': 'لا توجد بيانات كافية لتحليل الاتجاه',
};

const Map<String, String> _en = {
  'app_name': 'GlucoTrack',
  'app_tagline': 'Track your glucose with confidence',
  'nav_home': 'Home',
  'nav_chart': 'Chart',
  'nav_add': 'Add',
  'nav_reminders': 'Reminders',
  'nav_settings': 'Settings',
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'edit': 'Edit',
  'ok': 'OK',
  'close': 'Close',
  'back': 'Back',
  'welcome': 'Welcome',
  'choose_language': 'Choose Language',
  'choose_style': 'Choose Display Style',
  'style_classic': 'Classic Medical',
  'style_classic_desc': 'Elegant & professional, soft colors',
  'style_modern': 'Modern Youth',
  'style_modern_desc': 'Contemporary design, vibrant colors',
  'style_elder': 'Elder Friendly',
  'style_elder_desc': 'Large fonts, high contrast',
  'get_started': 'Get Started',
  'your_name': 'Your Name',
  'your_diabetes_type': 'Your Diabetes Type',
  'diabetes_type1': 'Type 1',
  'diabetes_type2': 'Type 2',
  'diabetes_gestational': 'Gestational',
  'good_morning': 'Good morning',
  'good_afternoon': 'Good afternoon',
  'good_evening': 'Good evening',
  'good_night': 'Good night',
  'latest_reading': 'Latest Reading',
  'avg_today': 'Daily Average',
  'readings_count': 'Readings',
  'in_range_pct': 'Time in Range',
  'no_readings_yet': 'No readings yet',
  'add_first_reading': 'Add your first reading now',
  'recent_readings': 'Recent Readings',
  'view_all': 'View All',
  'today': 'Today',
  'yesterday': 'Yesterday',
  'type_fasting': 'Fasting',
  'type_before_meal': 'Before Meal',
  'type_after_meal': 'After Meal',
  'type_before_sleep': 'Before Sleep',
  'type_after_exercise': 'After Exercise',
  'type_other': 'Other',
  'status_low': 'Low',
  'status_in_range': 'In Range',
  'status_high': 'High',
  'status_critical_low': 'Critical Low',
  'status_critical_high': 'Critical High',
  'add_reading': 'Add New Reading',
  'edit_reading': 'Edit Reading',
  'glucose_value': 'Glucose Value',
  'measurement_type': 'Measurement Type',
  'time': 'Time',
  'notes': 'Notes',
  'notes_placeholder': 'Add a note (optional)',
  'carbs_grams': 'Carbs (g)',
  'insulin_units': 'Insulin (units)',
  'saved_success': 'Reading saved successfully',
  'edited_success': 'Reading updated successfully',
  'deleted_success': 'Reading deleted',
  'invalid_value': 'Enter a valid value (20-600)',
  'delete_confirm': 'Do you want to delete this reading?',
  'delete_reading': 'Delete Reading',
  'chart': 'Chart',
  'period_today': 'Today',
  'period_week': 'Week',
  'period_month': 'Month',
  'glucose_chart': 'Glucose Curve',
  'stat_avg': 'Average',
  'stat_max': 'Max',
  'stat_min': 'Min',
  'stat_readings': 'Readings',
  'stat_in_range': 'In Range',
  'no_data_period': 'No data in this period',
  'sort_by': 'Sort by',
  'sort_newest': 'Newest',
  'sort_oldest': 'Oldest',
  'sort_highest': 'Highest',
  'sort_lowest': 'Lowest',
  'reminders': 'Reminders',
  'add_reminder': 'Add Reminder',
  'reminder_time': 'Time',
  'reminder_label': 'Label',
  'no_reminders': 'No reminders yet',
  'reminder_added': 'Reminder added',
  'reminder_deleted': 'Reminder deleted',
  'settings': 'Settings',
  'appearance': 'Appearance',
  'language': 'Language',
  'display_style': 'Display Style',
  'health': 'Health',
  'diabetes_type': 'Diabetes Type',
  'glucose_targets': 'Target Range',
  'target_min': 'Minimum',
  'target_max': 'Maximum',
  'glucose_unit': 'Measurement Unit',
  'unit_mg': 'mg/dL',
  'unit_mmol': 'mmol/L',
  'profile': 'Profile',
  'name': 'Name',
  'integrations': 'Integrations',
  'device_integration': 'Device Integration',
  'coming_soon': 'Coming Soon',
  'coming_soon_desc': 'Accu-Chek & FreeStyle Libre support coming soon',
  'about': 'About',
  'version': 'Version',
  'reset_data': 'Reset Data',
  'reset_confirm': 'Are you sure you want to delete all data?',
  'reset_done': 'Reset complete',
  'save_settings': 'Settings saved',
  'loading': 'Loading...',
  // New feature translations - English
  'search_hint': 'Search readings...',
  'search_by_value': 'Value',
  'search_by_type': 'Type',
  'search_by_notes': 'Notes',
  'filter_all_types': 'All Types',
  'no_search_results': 'No matching results',
  'trend_label': 'Trend',
  'trend_rising_fast': 'Rising Fast',
  'trend_rising': 'Rising',
  'trend_stable': 'Stable',
  'trend_falling': 'Falling',
  'trend_falling_fast': 'Falling Fast',
  'hba1c_title': 'HbA1c Estimate',
  'hba1c_estimate': 'Estimated HbA1c',
  'hba1c_average': 'Estimated Average Glucose',
  'hba1c_normal': 'Normal',
  'hba1c_prediabetes': 'Prediabetes',
  'hba1c_diabetes': 'Diabetes Range',
  'hba1c_no_data': 'Not enough data to estimate HbA1c',
  'weekly_summary': 'Weekly Summary',
  'this_week': 'This Week',
  'last_week': 'Last Week',
  'readings_this_week': 'Readings This Week',
  'avg_this_week': 'Weekly Average',
  'time_in_range_week': 'Time in Range',
  'high_readings': 'High Readings',
  'low_readings': 'Low Readings',
  'no_readings_this_week': 'No readings this week',
  'export_data': 'Export Data',
  'import_data': 'Import Data',
  'export_json': 'Export JSON',
  'export_csv': 'Export CSV',
  'share_backup': 'Share Backup',
  'import_success': 'Successfully imported {count} readings',
  'import_error': 'Failed to import file. Invalid format.',
  'export_success': 'Data exported successfully',
  'medication_log': 'Medication Log',
  'add_medication': 'Add Medication',
  'medication_name': 'Medication Name',
  'medication_dose': 'Dose',
  'medication_time': 'Time',
  'insulin_log': 'Insulin Log',
  'total_insulin_today': 'Total Insulin Today',
  'insulin_units_short': 'units',
  'notification_settings': 'Notification Settings',
  'enable_notifications': 'Enable Notifications',
  'reminder_notification': 'Glucose measurement reminder',
  'unit_mmol_l_full': 'mmol/L',
  'insights': 'Insights',
  'glucose_insights': 'Glucose Insights',
  'no_trend_data': 'Not enough data for trend analysis',
};
