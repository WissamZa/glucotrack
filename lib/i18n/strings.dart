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
  String get statusWarningLow => get('status_warning_low');
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

  // Tooltips (FIX-016 UX-001) — accessibility labels for IconButtons.
  String get tooltipAddReading => get('tooltip_add_reading');
  String get tooltipEdit => get('tooltip_edit');
  String get tooltipDelete => get('tooltip_delete');
  String get tooltipClose => get('tooltip_close');
  String get tooltipDecreaseValue => get('tooltip_decrease_value');
  String get tooltipIncreaseValue => get('tooltip_increase_value');
  String get tooltipMoreOptions => get('tooltip_more_options');
  String get tooltipSort => get('tooltip_sort');
  String get tooltipHelp => get('tooltip_help');
  String get tooltipRetry => get('tooltip_retry');
  String get tooltipCancel => get('tooltip_cancel');
  String get tooltipSave => get('tooltip_save');

  // Disclaimers (UX-002) — medical accuracy notices for HbA1c & trend arrows.
  String get disclaimerHba1c => get('disclaimer_hba1c');
  String get disclaimerTrend => get('disclaimer_trend');

  // Target-range validation errors (UX-002).
  String get errorTargetRangeInvalid => get('error_target_range_invalid');
  String get errorTargetRangeTooNarrow => get('error_target_range_too_narrow');

  // BLE sync screen strings (FIX-017 UX-002) — were previously hardcoded English.
  String get bleSyncTitle => get('ble_sync_title');
  String get bleHelpTooltip => get('ble_help_tooltip');
  String get bleUnavailableTitle => get('ble_unavailable_title');
  String get bleUnavailableDesc => get('ble_unavailable_desc');
  String get bleAvailablePlatforms => get('ble_available_platforms');
  String get bleScanButton => get('ble_scan_button');
  String get bleScanning => get('ble_scanning');
  String get bleScanningHint => get('ble_scanning_hint');
  String get bleMetersFound(int count) =>
      get('ble_meters_found').replaceAll('{count}', '$count');
  String get bleConnect => get('ble_connect');
  String get blePleaseEnableBt => get('ble_please_enable_bt');
  String get bleNoMetersFound => get('ble_no_meters_found');
  String bleScanFailed(Object error) =>
      get('ble_scan_failed').replaceAll('{error}', '$error');
  String bleSyncedRecords(int count) =>
      get('ble_synced_records').replaceAll('{count}', '$count');
  String bleSaveSelected(int count) =>
      get('ble_save_selected').replaceAll('{count}', '$count');
  String get bleSelectAllNew => get('ble_select_all_new');
  String get bleDeselectAllNew => get('ble_deselect_all_new');
  String get bleRecordsSaved => get('ble_records_saved');
  String get bleSaved => get('ble_saved');
  String bleDebugLog(int count) =>
      get('ble_debug_log').replaceAll('{count}', '$count');
  String get bleStartOver => get('ble_start_over');
  String get bleHelpTitle => get('ble_help_title');
  String get bleHelpStep1 => get('ble_help_step1');
  String get bleHelpStep1Detail => get('ble_help_step1_detail');
  String get bleHelpStep2 => get('ble_help_step2');
  String get bleHelpStep3 => get('ble_help_step3');
  String get bleHelpStep4 => get('ble_help_step4');
  String get bleHelpStep5 => get('ble_help_step5');
  String get bleHelpStep6 => get('ble_help_step6');
  String get bleTips => get('ble_tips');
  String get bleTipsText => get('ble_tips_text');
  String get bleGotIt => get('ble_got_it');
  String get bleHeroDevice => get('ble_hero_device');
  String get bleHeroDesc => get('ble_hero_desc');
  String get blePairingTitle => get('ble_pairing_title');
  String get blePairingDesc => get('ble_pairing_desc');
  String get bleSyncedFromMeter => get('ble_synced_from_meter');
  String bleSaveResult(int inserted, int skipped) => get('ble_save_result')
      .replaceAll('{inserted}', '$inserted')
      .replaceAll('{skipped}', skipped > 0 ? get('ble_skipped_duplicates').replaceAll('{count}', '$skipped') : '');
  String get bleControlSolution => get('ble_control_solution');
  String get bleBeforeMealShort => get('ble_before_meal_short');
  String get bleAfterMealShort => get('ble_after_meal_short');
  String get bleFailed => get('ble_failed');
  String blePercentComplete(int percent) =>
      get('ble_percent_complete').replaceAll('{percent}', '$percent');
  String get blePhaseIdle => get('ble_phase_idle');
  String get blePhaseScanning => get('ble_phase_scanning');
  String get blePhaseConnecting => get('ble_phase_connecting');
  String get blePhaseDiscovering => get('ble_phase_discovering');
  String get blePhaseSubscribing => get('ble_phase_subscribing');
  String get blePhaseReadingMetadata => get('ble_phase_reading_metadata');
  String get blePhaseReadingRecords => get('ble_phase_reading_records');
  String get blePhaseDone => get('ble_phase_done');
  String get blePhaseError => get('ble_phase_error');
  // Sync-from-meter banner (home_screen.dart).
  String get bleSyncBannerTitle => get('ble_sync_banner_title');
  String get bleSyncBannerSupported => get('ble_sync_banner_supported');
  String get bleSyncBannerUnsupported => get('ble_sync_banner_unsupported');

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
      case ReadingStatus.criticalLow:
        return get('status_critical_low');
      case ReadingStatus.warningLow:
        return get('status_warning_low');
      case ReadingStatus.low:
        return get('status_low');
      case ReadingStatus.inRange:
        return get('status_in_range');
      case ReadingStatus.high:
        return get('status_high');
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
  'status_warning_low': 'تحذير منخفض',
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
  // Tooltips + semantics (FIX-016 UX-001)
  'tooltip_add_reading': 'إضافة قراءة',
  'tooltip_edit': 'تعديل',
  'tooltip_delete': 'حذف',
  'tooltip_close': 'إغلاق',
  'tooltip_decrease_value': 'إنقاص 10',
  'tooltip_increase_value': 'زيادة 10',
  'tooltip_more_options': 'خيارات أخرى',
  'tooltip_sort': 'ترتيب',
  'tooltip_help': 'مساعدة',
  'tooltip_retry': 'إعادة المحاولة',
  'tooltip_cancel': 'إلغاء',
  'tooltip_save': 'حفظ',
  // Disclaimers (UX-002)
  'disclaimer_hba1c': 'هذا التقدير لـ HbA1c مبني على قراءات الوخز، وليس على جهاز قياس مستمر. قد يختلف عن نتيجة المختبر بنسبة تصل إلى ±1.5%. استشر طبيبك قبل اتخاذ قرارات علاجية.',
  'disclaimer_trend': 'أسهم الاتجاه مبنية على آخر قراءتين وقد لا تعكس تغيرات السكر في الوقت الفعلي. لا تستخدمها لتحديد جرعة الإنسولين.',
  // Target-range validation errors (UX-002)
  'error_target_range_invalid': 'الحد الأدنى يجب أن يكون أقل من الحد الأعلى',
  'error_target_range_too_narrow': 'النطاق المستهدف ضيق جداً (الحد الأدنى 20 ملغ/ديسيلتر)',
  // BLE sync screen (FIX-017 UX-002)
  'ble_sync_title': 'مزامنة من الجهاز',
  'ble_help_tooltip': 'كيفية المزامنة',
  'ble_unavailable_title': 'مزامنة BLE غير متاحة',
  'ble_unavailable_desc': 'مزامنة Bluetooth LE غير مدعومة على هذه المنصة.',
  'ble_available_platforms': 'متاح على أندرويد و iOS',
  'ble_scan_button': 'ابحث عن أجهزة OneTouch',
  'ble_scanning': 'جارٍ البحث عن أجهزة OneTouch…',
  'ble_scanning_hint': 'تأكد من تشغيل البلوتوث على الجهاز (▲+▼)',
  'ble_meters_found': 'تم العثور على {count} جهاز قريب',
  'ble_connect': 'اتصال',
  'ble_please_enable_bt': 'يرجى تشغيل البلوتوث والمحاولة مرة أخرى.',
  'ble_no_meters_found': 'لم يتم العثور على أجهزة OneTouch. تأكد من تشغيل بلوتوث الجهاز (اضغط ▲+▼ على الجهاز).',
  'ble_scan_failed': 'فشل البحث: {error}',
  'ble_synced_records': 'السجلات المتزامنة ({count})',
  'ble_save_selected': 'حفظ المحدد ({count})',
  'ble_select_all_new': 'تحديد الكل الجديد',
  'ble_deselect_all_new': 'إلغاء تحديد الكل الجديد',
  'ble_records_saved': 'تم حفظ السجلات في GlucoTrack',
  'ble_saved': 'تم الحفظ',
  'ble_debug_log': 'سجل التصحيح ({count} أسطر)',
  'ble_start_over': 'البدء من جديد',
  'ble_help_title': 'كيفية مزامنة جهازك',
  'ble_help_step1': 'ضع الجهاز في وضع البلوتوث:',
  'ble_help_step1_detail': '• اضغط OK لتشغيل الجهاز\n• اضغط ▲ + ▼ معاً — يظهر رمز البلوتوث',
  'ble_help_step2': 'اضغط "ابحث عن أجهزة OneTouch"',
  'ble_help_step3': 'اضغط على جهازك في القائمة',
  'ble_help_step4': 'أدخل رقم التعريف الشخصي المكوّن من 6 أرقام الظاهر على شاشة الجهاز عند ظهور مربع حوار الاقتران',
  'ble_help_step5': 'انتظر إكمال المزامنة',
  'ble_help_step6': 'اضغط "حفظ الكل" لحفظ السجلات في GlucoTrack',
  'ble_tips': 'نصائح',
  'ble_tips_text': '• البلوتوث ينطفئ أثناء فحص الدم ويعود بعدها.\n• ابقَ ضمن 8 أمتار من الهاتف.\n• إعادة المزامنة لن تنشئ نسخاً مكررة — تُحدَّد السجلات برقم الجهاز + الرقم التسلسلي.',
  'ble_got_it': 'فهمت',
  'ble_hero_device': 'OneTouch Select Plus Flex',
  'ble_hero_desc': 'مزامنة قراءات السكر لاسلكياً عبر Bluetooth LE. تُحفظ السجلات محلياً على هذا الجهاز.',
  'ble_pairing_title': 'الاقتران لأول مرة',
  'ble_pairing_desc': 'يجب اقتران الجهاز مع هذا الهاتف عبر إعدادات بلوتوث أندرويد أولاً. عند ظهور مربع حوار الاقتران، أدخل رقم التعريف الشخصي المكوّن من 6 أرقام الظاهر على شاشة الجهاز.',
  'ble_synced_from_meter': 'تمت المزامنة من الجهاز',
  'ble_save_result': 'تم حفظ {inserted} قراءة جديدة{skipped}.',
  'ble_skipped_duplicates': '، تم تخطي {count} نسخة مكررة',
  'ble_control_solution': '(محلول فحص)',
  'ble_before_meal_short': 'قبل الأكل',
  'ble_after_meal_short': 'بعد الأكل',
  'ble_failed': 'فشل',
  'ble_percent_complete': '{percent}% مكتمل',
  'ble_phase_idle': 'خامل',
  'ble_phase_scanning': 'جارٍ البحث…',
  'ble_phase_connecting': 'جارٍ الاتصال…',
  'ble_phase_discovering': 'اكتشاف الخدمات…',
  'ble_phase_subscribing': 'الاشتراك في الإشعارات…',
  'ble_phase_reading_metadata': 'قراءة بيانات الجهاز…',
  'ble_phase_reading_records': 'قراءة السجلات…',
  'ble_phase_done': 'اكتملت المزامنة',
  'ble_phase_error': 'فشلت المزامنة',
  'ble_sync_banner_title': 'مزامنة من الجهاز',
  'ble_sync_banner_supported': 'OneTouch Select Plus Flex • اضغط للمزامنة',
  'ble_sync_banner_unsupported': 'متاح على أندرويد — غير متاح على هذه المنصة',
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
  'status_warning_low': 'Warning Low',
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
  // Tooltips + semantics (FIX-016 UX-001)
  'tooltip_add_reading': 'Add reading',
  'tooltip_edit': 'Edit',
  'tooltip_delete': 'Delete',
  'tooltip_close': 'Close',
  'tooltip_decrease_value': 'Decrease by 10',
  'tooltip_increase_value': 'Increase by 10',
  'tooltip_more_options': 'More options',
  'tooltip_sort': 'Sort',
  'tooltip_help': 'Help',
  'tooltip_retry': 'Retry',
  'tooltip_cancel': 'Cancel',
  'tooltip_save': 'Save',
  // Disclaimers (UX-002)
  'disclaimer_hba1c': 'This HbA1c estimate is based on finger-stick readings, not a continuous glucose monitor. It may differ from a lab HbA1c by up to ±1.5%. Consult your doctor for clinical decisions.',
  'disclaimer_trend': 'Trend arrows are based on your last two readings and may not reflect real-time glucose changes. Do not use for insulin dosing.',
  // Target-range validation errors (UX-002)
  'error_target_range_invalid': 'Target minimum must be less than target maximum',
  'error_target_range_too_narrow': 'Target range too narrow (minimum 20 mg/dL gap)',
  // BLE sync screen (FIX-017 UX-002)
  'ble_sync_title': 'Sync from Meter',
  'ble_help_tooltip': 'How to sync',
  'ble_unavailable_title': 'BLE Sync Not Available',
  'ble_unavailable_desc': 'Bluetooth LE sync is not supported on this platform.',
  'ble_available_platforms': 'Available on Android & iOS',
  'ble_scan_button': 'Scan for OneTouch meters',
  'ble_scanning': 'Scanning for OneTouch meters…',
  'ble_scanning_hint': 'Make sure BT is enabled on the meter (▲+▼)',
  'ble_meters_found': '{count} meter(s) found nearby',
  'ble_connect': 'Connect',
  'ble_please_enable_bt': 'Please turn on Bluetooth and try again.',
  'ble_no_meters_found': 'No OneTouch meters found. Make sure the meter\'s BT is on (press ▲+▼ on the meter).',
  'ble_scan_failed': 'Scan failed: {error}',
  'ble_synced_records': 'Synced records ({count})',
  'ble_save_selected': 'Save selected ({count})',
  'ble_select_all_new': 'Select all new',
  'ble_deselect_all_new': 'Deselect all new',
  'ble_records_saved': 'Records saved to GlucoTrack',
  'ble_saved': 'Saved',
  'ble_debug_log': 'Debug log ({count} lines)',
  'ble_start_over': 'Start over',
  'ble_help_title': 'How to sync your meter',
  'ble_help_step1': 'Put meter into BT mode:',
  'ble_help_step1_detail': '• Press OK to turn the meter on\n• Press ▲ + ▼ together — BT icon appears',
  'ble_help_step2': 'Tap "Scan for OneTouch meters"',
  'ble_help_step3': 'Tap your meter in the list',
  'ble_help_step4': 'Enter the 6-digit PIN shown on the meter LCD when the pairing dialog appears',
  'ble_help_step5': 'Wait for sync to complete',
  'ble_help_step6': 'Tap "Save all" to persist records to GlucoTrack',
  'ble_tips': 'Tips',
  'ble_tips_text': '• BT turns off during a blood test and back on afterwards.\n• Stay within 8 m of the phone.\n• Re-syncing won\'t create duplicates — records are identified by meter ID + sequence number.',
  'ble_got_it': 'Got it',
  'ble_hero_device': 'OneTouch Select Plus Flex',
  'ble_hero_desc': 'Sync glucose readings wirelessly over Bluetooth LE. Records are saved locally on this device.',
  'ble_pairing_title': 'First-time pairing',
  'ble_pairing_desc': 'The meter must be paired with this phone via Android Bluetooth settings first. When the pairing dialog appears, enter the 6-digit PIN shown on the meter\'s LCD screen.',
  'ble_synced_from_meter': 'Synced from meter',
  'ble_save_result': 'Saved {inserted} new reading(s){skipped}.',
  'ble_skipped_duplicates': ', skipped {count} duplicate(s)',
  'ble_control_solution': '(control solution)',
  'ble_before_meal_short': 'before meal',
  'ble_after_meal_short': 'after meal',
  'ble_failed': 'Failed',
  'ble_percent_complete': '{percent}% complete',
  'ble_phase_idle': 'Idle',
  'ble_phase_scanning': 'Scanning…',
  'ble_phase_connecting': 'Connecting…',
  'ble_phase_discovering': 'Discovering services…',
  'ble_phase_subscribing': 'Subscribing to notifications…',
  'ble_phase_reading_metadata': 'Reading meter metadata…',
  'ble_phase_reading_records': 'Reading records…',
  'ble_phase_done': 'Sync complete',
  'ble_phase_error': 'Sync failed',
  'ble_sync_banner_title': 'Sync from meter',
  'ble_sync_banner_supported': 'OneTouch Select Plus Flex • Tap to sync',
  'ble_sync_banner_unsupported': 'Available on Android — not on this platform',
};
