// App strings + SettingsProvider state.
//
// This file combines translations (AR/EN) with the SettingsProvider
// state management class to avoid circular imports.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  const SettingsInherited({
    super.key,
    required this.data,
    required super.child,
  });

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
  String importSuccess(int count) =>
      get('import_success').replaceAll('{count}', '$count');
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
  String bleMetersFound(int count) =>
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
      .replaceAll(
        '{skipped}',
        skipped > 0
            ? get('ble_skipped_duplicates').replaceAll('{count}', '$skipped')
            : '',
      );
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

  // ===== Health tips (v1.3) =====
  String get tips => get('tips');
  String get tipsDisclaimer => get('tips_disclaimer');
  String get tipOfTheDay => get('tip_of_the_day');
  String get viewAllTips => get('view_all_tips');
  String tipsCount(int count) =>
      get('tips_count').replaceAll('{count}', '$count');

  // ===== Emergency guidance (v1.3) =====
  String get latestCritical => get('latest_critical');
  String get immediateGuidance => get('immediate_guidance');
  String get emergencySeekHelp => get('emergency_seek_help');
  String get emergencyNote => get('emergency_note');

  // ===== Weight / BP / water tracking (v1.3) =====
  String get healthMetricsTitle => get('health_metrics_title');
  String get weightKg => get('weight_kg');
  String get heightCmLabel => get('height_cm_label');
  String get heightHint => get('height_hint');
  String get bloodPressure => get('blood_pressure');
  String get systolic => get('systolic');
  String get diastolic => get('diastolic');
  String get addEntry => get('add_entry');
  String get latestWeight => get('latest_weight');
  String get bmiLabel => get('bmi_label');
  String get bmiUnderweight => get('bmi_underweight');
  String get bmiNormal => get('bmi_normal');
  String get bmiOverweight => get('bmi_overweight');
  String get bmiObese => get('bmi_obese');
  String get weightTrend => get('weight_trend');
  String get noMetricsYet => get('no_metrics_yet');
  String get addFirstMetric => get('add_first_metric');
  String get metricSaved => get('metric_saved');
  String get metricDeleted => get('metric_deleted');
  String get errorWeight => get('error_weight');
  String get errorHeight => get('error_height');
  String get errorBp => get('error_bp');
  String get errorMetricEmpty => get('error_metric_empty');
  String get deleteMetricConfirm => get('delete_metric_confirm');
  String get healthTrackingCard => get('health_tracking_card');
  String get waterTracker => get('water_tracker');
  String waterProgress(int count, int goal) =>
      get('water_progress')
          .replaceAll('{count}', '$count')
          .replaceAll('{goal}', '$goal');
  String get waterGoalReached => get('water_goal_reached');
  String get waterLast7 => get('water_last7');

  // ===== Medication reminders (v1.3) =====
  String get reminderKind => get('reminder_kind');
  String get kindMeasurement => get('kind_measurement');
  String get kindMedication => get('kind_medication');
  String get errorMedicationName => get('error_medication_name');

  // ===== Medication schedule (v1.4) =====
  String get reminderDays => get('reminder_days');
  String get everyDay => get('every_day');
  String get addTime => get('add_time');
  String get timesPerDay => get('times_per_day');
  String get duplicateTime => get('duplicate_time');
  String takenToday(int count, int total) =>
      get('taken_today')
          .replaceAll('{count}', '$count')
          .replaceAll('{total}', '$total');
  String get allDosesTaken => get('all_doses_taken');
  String get markTaken => get('mark_taken');
  String get medicationHistory => get('medication_history');
  String get noMedicationLog => get('no_medication_log');
  String get editReminder => get('edit_reminder');

  /// Localized label for a reminder's day pattern.
  String daysPatternLabel(String pattern) => get(pattern);

  /// Localized weekday short names (Sat..Fri) for the 7-day selector.
  List<String> weekdayShortNames() {
    // 2026-09-07 is a Monday — same order as Reminder.daysMask bits.
    final base = DateTime(2026, 9, 7);
    final locale = lang.code;
    return [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(base.add(Duration(days: i))),
    ];
  }

  // ===== Insulin preference (v1.4) =====
  String get usesInsulinLabel => get('uses_insulin');
  String get usesInsulinHint => get('uses_insulin_hint');

  // ===== Medication auto-schedule (v1.5) =====
  String get doseCount => get('dose_count');
  String get firstDoseTime => get('first_dose_time');
  String get autoScheduleHint => get('auto_schedule_hint');

  // ===== Medication lookup & structured dose (v1.6) =====
  String get doseForm => get('dose_form');
  String get doseAmount => get('dose_amount');
  String get searchMedication => get('search_medication');
  String get noSuggestions => get('no_suggestions');
  String get medicationDetails => get('medication_details');
  String get medSynonym => get('med_synonym');
  String get medStrength => get('med_strength');
  String get medTypeBrand => get('med_type_brand');
  String get medTypeGeneric => get('med_type_generic');
  String get medSourceRxNorm => get('med_source_rxnorm');
  String get medOpenDetails => get('med_open_details');
  String get medGenericTerm => get('med_generic_term');
  String get errorDoseAmount => get('error_dose_amount');

  // ===== Medications tab & drug sources (v1.7) =====
  String get medicationsTitle => get('medications_title');
  String get medsSearchHint => get('meds_search_hint');
  String get yourMedications => get('your_medications');
  String get fromCache => get('from_cache');
  String get noResultsSourceHint => get('no_results_source_hint');
  String get drugSourceLabel => get('drug_source_label');
  String get ingredientsLabel => get('ingredients_label');
  String get indicationsLabel => get('indications_label');
  String get rxBadge => get('rx_badge');
  String get otcBadge => get('otc_badge');
  String get notFromSource => get('not_from_source');
  String get nahdiPrice => get('nahdi_price');
  String get nahdiPriceNote => get('nahdi_price_note');
  String get priceUnavailable => get('price_unavailable');
  String sourceLabel(String id) => get('source_$id');
  String sourceDesc(String id) => get('source_${id}_desc');

  String? doseFormLabel(String? key) {
    if (key == null) return null;
    final v = get('dose_form_$key');
    return v == 'dose_form_$key' ? key : v;
  }

  // ===== WebDAV sync (v1.5) =====
  String get webdavSync => get('webdav_sync');
  String get webdavSyncNow => get('webdav_sync_now');
  String get webdavRestore => get('webdav_restore');
  String get webdavDesc => get('webdav_desc');
  String get webdavUrl => get('webdav_url');
  String get webdavUsername => get('webdav_username');
  String get webdavPassword => get('webdav_password');
  String get webdavEncrypt => get('webdav_encrypt');
  String get webdavEncryptHint => get('webdav_encrypt_hint');
  String get webdavPassphrase => get('webdav_passphrase');
  String get webdavSaveTest => get('webdav_save_test');
  String get webdavTestOk => get('webdav_test_ok');
  String webdavTestFail(String error) =>
      get('webdav_test_fail').replaceAll('{error}', error);
  String get webdavEdit => get('webdav_edit');
  String get webdavRemove => get('webdav_remove');
  String webdavLastSync(String date) =>
      get('webdav_last_sync').replaceAll('{date}', date);
  String get webdavEncryptedBadge => get('webdav_encrypted_badge');
  String get webdavNeverSynced => get('webdav_never_synced');
  String get webdavWhatIsTitle => get('webdav_what_is_title');
  String get webdavWhatIsBody => get('webdav_what_is_body');
  String get webdavSynced => get('webdav_synced');
  String get webdavRestored => get('webdav_restored');
  String get webdavNoBackupRestore => get('webdav_no_backup_restore');
  String get webdavWrongPassphrase => get('webdav_wrong_passphrase');
  String get restoreConfirm => get('restore_confirm');

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
  'error_target_range_too_narrow':
      'النطاق المستهدف ضيق جداً (الحد الأدنى 20 ملغ/ديسيلتر)',
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
  'ble_help_step1_detail':
      '• اضغط OK لتشغيل الجهاز\n• اضغط ▲ + ▼ معاً — يظهر رمز البلوتوث',
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
  // Health tips (v1.3)
  'tips': 'النصائح',
  'tips_disclaimer': 'هذه النصائح تثقيف عام لمرضى السكري وليست بديلاً عن رأي الطبيب. استشر فريق الرعاية الصحية قبل تطبيق أي تغيير على علاجك أو نظامك الغذائي.',
  'tip_of_the_day': 'نصيحة اليوم',
  'view_all_tips': 'كل النصائح',
  'tips_count': '{count} نصيحة',
  // Emergency guidance (v1.3)
  'latest_critical': 'آخر قراءة حرجة',
  'immediate_guidance': 'اضغط لعرض الإرشادات الفورية',
  'emergency_seek_help': 'متى تطلب المساعدة؟',
  'emergency_note': 'إرشادات عامة للإسعاف الذاتي وليست بديلاً عن استشارة الطبيب. عند الشك، اتصل بالإسعاف أو طبيبك.',
  // Weight / BP / water (v1.3)
  'health_metrics_title': 'الوزن والضغط',
  'weight_kg': 'الوزن (كجم)',
  'height_cm_label': 'الطول (سم)',
  'height_hint': 'يُستخدم لحساب مؤشر كتلة الجسم (اختياري)',
  'blood_pressure': 'ضغط الدم',
  'systolic': 'الانقباضي (الأعلى)',
  'diastolic': 'الانبساطي (الأدنى)',
  'add_entry': 'إضافة قياس',
  'latest_weight': 'آخر وزن',
  'bmi_label': 'مؤشر كتلة الجسم (BMI)',
  'bmi_underweight': 'نقص وزن',
  'bmi_normal': 'وزن طبيعي',
  'bmi_overweight': 'زيادة وزن',
  'bmi_obese': 'سمنة',
  'weight_trend': 'تطور الوزن',
  'no_metrics_yet': 'لا توجد قياسات وزن أو ضغط بعد',
  'add_first_metric': 'سجّل وزنك أو ضغطك الأول',
  'metric_saved': 'تم حفظ القياس',
  'metric_deleted': 'تم حذف القياس',
  'error_weight': 'أدخل وزناً صحيحاً (20–400 كجم)',
  'error_height': 'أدخل طولاً صحيحاً (80–250 سم)',
  'error_bp': 'أدخل ضغطاً صحيحاً (انقباضي 60–260، انبساطي 30–150)',
  'error_metric_empty': 'أدخل وزناً أو ضغط دم على الأقل',
  'delete_metric_confirm': 'حذف هذا القياس؟',
  'health_tracking_card': 'متابعة الوزن والضغط والماء',
  'water_tracker': 'تتبع الماء',
  'water_progress': '{count} من {goal} أكواب',
  'water_goal_reached': 'أحسنت! حققت هدف اليوم',
  'water_last7': 'آخر 7 أيام',
  // Medication reminders (v1.3)
  'reminder_kind': 'نوع التذكير',
  'kind_measurement': 'قياس السكر',
  'kind_medication': 'دواء',
  'error_medication_name': 'أدخل اسم الدواء',
  // Medication schedule (v1.4)
  'reminder_days': 'الأيام',
  'every_day': 'كل الأيام',
  'weekdays_pattern': 'أيام العمل',
  'weekend_pattern': 'الجمعة والسبت',
  'custom_days': 'أيام مخصصة',
  'add_time': 'إضافة وقت',
  'times_per_day': 'المرات يومياً',
  'duplicate_time': 'هذا الوقت مضاف بالفعل',
  'taken_today': 'تم اليوم {count} من {total}',
  'all_doses_taken': 'اكتملت جرعات اليوم',
  'mark_taken': 'تناولته الآن',
  'medication_history': 'سجل تناول الدواء',
  'no_medication_log': 'لا يوجد سجل تناول بعد',
  'edit_reminder': 'تعديل التذكير',
  // Insulin preference (v1.4)
  'uses_insulin': 'أستخدم الأنسولين',
  'uses_insulin_hint': 'يُظهر حقل جرعة الأنسولين عند إضافة القراءات',
  // Google Drive sync (v1.4)
  'restore_confirm': 'سيتم دمج النسخة الاحتياطية مع بياناتك الحالية بدون ازدواج. هل تريد المتابعة؟',
  // Medication auto-schedule (v1.5)
  'dose_count': 'عدد الجرعات يومياً',
  'first_dose_time': 'وقت الجرعة الأولى',
  'auto_schedule_hint':
      'تُولّد بقية الأوقات تلقائياً — انقر على أي وقت لتعديله',
  'dose_form': 'شكل الجرعة',
  'dose_amount': 'الكمية لكل جرعة',
  'dose_form_tablet': 'حبة',
  'dose_form_capsule': 'كبسولة',
  'dose_form_ml': 'مل',
  'dose_form_drops': 'قطرة',
  'dose_form_spray': 'بخاخ',
  'dose_form_cream': 'كريم',
  'dose_form_injection': 'حقنة',
  'dose_form_units': 'وحدة أنسولين',
  'search_medication': 'ابحث عن اسم الدواء…',
  'no_suggestions': 'لا توجد اقتراحات — أكمل الاسم يدوياً',
  'medication_details': 'تفاصيل الدواء',
  'med_synonym': 'الاسم البديل',
  'med_strength': 'التركيز',
  'med_type_brand': 'اسم تجاري',
  'med_type_generic': 'اسم علمي',
  'med_source_rxnorm':
      'المصدر: RxNorm — المكتبة الوطنية الأمريكية للطب (ملكية عامة)',
  'med_open_details': 'عرض تفاصيل الدواء',
  'med_generic_term': 'غير محدد',
  'error_dose_amount': 'أدخل كمية صحيحة للجرعة',
  'medications_title': 'الأدوية',
  'meds_search_hint': 'ابحث عن دواء (عربي أو إنجليزي)…',
  'your_medications': 'أدويتك من التذكيرات',
  'from_cache': 'تم البحث عنها سابقاً',
  'no_results_source_hint': 'لا نتائج — للمصادر الدولية اكتب الاسم بالإنجليزية',
  'drug_source_label': 'مصدر بيانات الأدوية',
  'ingredients_label': 'المكونات',
  'indications_label': 'دواعي الاستخدام',
  'rx_badge': 'بوصفة طبية',
  'otc_badge': 'بدون وصفة',
  'not_from_source':
      'غير متوفر من هذا المصدر — جرّب مصدراً آخر من تبويب الأدوية',
  'nahdi_price': 'السعر في صيدلية النهدي',
  'nahdi_price_note': 'سعر تقريبي من موقع النهدي الإلكتروني — قابل للتغير',
  'price_unavailable': 'لم يتم العثور على سعر لهذا الدواء',
  'source_saudi': 'السعودية 🇸🇦 (مدمجة)',
  'source_saudi_desc': 'قاعدة مدمجة بأشهر أدوية السوق السعودي — تعمل بدون إنترنت وتدعم البحث بالعربية',
  'source_rxnorm': 'دولي (RxNorm)',
  'source_rxnorm_desc': 'قاعدة RxNorm الدولية — المكتبة الوطنية الأمريكية للطب، تغطي الأسماء العلمية والتجارية العالمية',
  'source_openfda': 'أمريكي (openFDA)',
  'source_openfda_desc': 'بيانات ملصقات الأدوية الأمريكية من openFDA — تفاصيل-rich عن الأشكال والاستخدامات',
  // WebDAV sync (v1.5)
  // WebDAV sync (v1.5)
  'webdav_sync': 'المزامنة عبر WebDAV',
  'webdav_sync_now': 'مزامنة الآن',
  'webdav_restore': 'استعادة',
  'webdav_desc': 'اربط خادم WebDAV خاص بك (Nextcloud، Koofr، Synology...) — بلا تسجيل مطوّر، والنسخة تُشفّر على هاتفك قبل رفعها فلا يقرأ الخادم محتواها.',
  'webdav_url': 'عنوان مجلد WebDAV',
  'webdav_username': 'اسم المستخدم',
  'webdav_password': 'كلمة المرور',
  'webdav_encrypt': 'تشفير النسخة قبل الرفع',
  'webdav_encrypt_hint': 'لا يمكن فك النسخة على الخادم إلا بكلمة مرور التشفير — احفظها في مكان آمن',
  'webdav_passphrase': 'كلمة مرور التشفير',
  'webdav_save_test': 'حفظ واختبار الاتصال',
  'webdav_test_ok': 'الاتصال ناجح — تم حفظ الإعدادات',
  'webdav_test_fail': 'فشل الاتصال: {error}',
  'webdav_edit': 'تعديل الإعدادات',
  'webdav_remove': 'إزالة الإعداد',
  'webdav_last_sync': 'آخر مزامنة: {date}',
  'webdav_encrypted_badge': 'مشفرة',
  'webdav_never_synced': 'لم تتم أي مزامنة بعد',
  'webdav_what_is_title': 'ما هو WebDAV؟',
  'webdav_what_is_body': 'WebDAV بروتوكول تخزين سحابي قياسي تدعمه خدمات كثيرة: خادم Nextcloud الشخصي، Koofr، Synology، وغيرها. أنشئ مجلداً على الخدمة التي تفضلها، أدخل عنوانه وبيانات الدخول هنا، وسيتولى التطبيق رفع نسخة مشفرة بالكامل من بياناتك واستعادتها على أي جهاز — دون أي تسجيل للمطور لدى مزود خدمة.',
  'webdav_synced': 'تمت المزامنة بنجاح',
  'webdav_restored': 'تم استيراد النسخة الاحتياطية',
  'webdav_no_backup_restore': 'لا توجد نسخة للاستعادة على الخادم',
  'webdav_wrong_passphrase': 'كلمة مرور التشفير غير صحيحة',
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
  'error_target_range_invalid':
      'Target minimum must be less than target maximum',
  'error_target_range_too_narrow':
      'Target range too narrow (minimum 20 mg/dL gap)',
  // BLE sync screen (FIX-017 UX-002)
  'ble_sync_title': 'Sync from Meter',
  'ble_help_tooltip': 'How to sync',
  'ble_unavailable_title': 'BLE Sync Not Available',
  'ble_unavailable_desc':
      'Bluetooth LE sync is not supported on this platform.',
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
  // Health tips (v1.3)
  'tips': 'Health Tips',
  'tips_disclaimer': 'These tips are general diabetes education, not medical advice. Consult your care team before changing your treatment or diet.',
  'tip_of_the_day': 'Tip of the Day',
  'view_all_tips': 'All Tips',
  'tips_count': '{count} tips',
  // Emergency guidance (v1.3)
  'latest_critical': 'Latest critical reading',
  'immediate_guidance': 'Tap for immediate guidance',
  'emergency_seek_help': 'When to seek help?',
  'emergency_note': 'General self-care first-aid guidance, not a substitute for medical advice. When in doubt, call emergency services or your doctor.',
  // Weight / BP / water (v1.3)
  'health_metrics_title': 'Weight & Blood Pressure',
  'weight_kg': 'Weight (kg)',
  'height_cm_label': 'Height (cm)',
  'height_hint': 'Used for BMI calculation (optional)',
  'blood_pressure': 'Blood Pressure',
  'systolic': 'Systolic (upper)',
  'diastolic': 'Diastolic (lower)',
  'add_entry': 'Add entry',
  'latest_weight': 'Latest weight',
  'bmi_label': 'Body Mass Index (BMI)',
  'bmi_underweight': 'Underweight',
  'bmi_normal': 'Normal weight',
  'bmi_overweight': 'Overweight',
  'bmi_obese': 'Obese',
  'weight_trend': 'Weight Trend',
  'no_metrics_yet': 'No weight or blood pressure entries yet',
  'add_first_metric': 'Add your first weight or BP entry',
  'metric_saved': 'Entry saved',
  'metric_deleted': 'Entry deleted',
  'error_weight': 'Enter a valid weight (20–400 kg)',
  'error_height': 'Enter a valid height (80–250 cm)',
  'error_bp':
      'Enter a valid blood pressure (systolic 60–260, diastolic 30–150)',
  'error_metric_empty': 'Enter a weight or a blood pressure',
  'delete_metric_confirm': 'Delete this entry?',
  'health_tracking_card': 'Weight, BP & Water Tracking',
  'water_tracker': 'Water Tracker',
  'water_progress': '{count} of {goal} cups',
  'water_goal_reached': 'Great! Daily goal reached',
  'water_last7': 'Last 7 days',
  // Medication reminders (v1.3)
  'reminder_kind': 'Reminder Type',
  'kind_measurement': 'Glucose check',
  'kind_medication': 'Medication',
  'error_medication_name': 'Enter the medication name',
  // Medication schedule (v1.4)
  'reminder_days': 'Days',
  'every_day': 'Every day',
  'weekdays_pattern': 'Weekdays',
  'weekend_pattern': 'Weekend',
  'custom_days': 'Custom days',
  'add_time': 'Add time',
  'times_per_day': 'Times per day',
  'duplicate_time': 'This time is already added',
  'taken_today': 'Taken today {count} of {total}',
  'all_doses_taken': 'All doses taken',
  'mark_taken': 'Taken now',
  'medication_history': 'Medication Log',
  'no_medication_log': 'No doses logged yet',
  'edit_reminder': 'Edit Reminder',
  // Insulin preference (v1.4)
  'uses_insulin': 'I use insulin',
  'uses_insulin_hint': 'Shows the insulin dose field when adding readings',
  // Google Drive sync (v1.4)
  'restore_confirm': 'The backup will be merged with your current data without duplicates. Continue?',
  // Medication auto-schedule (v1.5)
  'dose_count': 'Doses per day',
  'first_dose_time': 'First dose time',
  'auto_schedule_hint': 'The remaining times are generated automatically — tap any time to edit it',
  'dose_form': 'Dose form',
  'dose_amount': 'Amount per dose',
  'dose_form_tablet': 'Tablet',
  'dose_form_capsule': 'Capsule',
  'dose_form_ml': 'ml',
  'dose_form_drops': 'Drops',
  'dose_form_spray': 'Spray',
  'dose_form_cream': 'Cream',
  'dose_form_injection': 'Injection',
  'dose_form_units': 'Insulin units',
  'search_medication': 'Search medication name…',
  'no_suggestions': 'No suggestions — finish typing manually',
  'medication_details': 'Medication Details',
  'med_synonym': 'Synonym',
  'med_strength': 'Strength',
  'med_type_brand': 'Brand name',
  'med_type_generic': 'Generic name',
  'med_source_rxnorm':
      'Source: RxNorm — U.S. National Library of Medicine (public domain)',
  'med_open_details': 'View medication details',
  'med_generic_term': 'Unknown',
  'error_dose_amount': 'Enter a valid dose amount',
  'medications_title': 'Medications',
  'meds_search_hint': 'Search a drug (Arabic or English)…',
  'your_medications': 'Your medications',
  'from_cache': 'Previously looked up',
  'no_results_source_hint':
      'No results — international sources need English names',
  'drug_source_label': 'Drug data source',
  'ingredients_label': 'Ingredients',
  'indications_label': 'Indications',
  'rx_badge': 'Prescription required',
  'otc_badge': 'No prescription needed',
  'not_from_source': 'Not available from this source — try another source in the Medications tab',
  'nahdi_price': 'Nahdi Pharmacy price',
  'nahdi_price_note': 'Approximate price from Nahdi online — may change',
  'price_unavailable': 'No price found for this drug',
  'source_saudi': 'Saudi 🇸🇦 (bundled)',
  'source_saudi_desc': 'Bundled library of the most common Saudi-market drugs — offline, supports Arabic search',
  'source_rxnorm': 'International (RxNorm)',
  'source_rxnorm_desc': 'The international RxNorm registry — U.S. National Library of Medicine, covers global generic and brand names',
  'source_openfda': 'US (openFDA)',
  'source_openfda_desc':
      'US drug-label data from openFDA — rich form and usage details',
  // WebDAV sync (v1.5)
  'webdav_sync': 'WebDAV Sync',
  'webdav_sync_now': 'Sync now',
  'webdav_restore': 'Restore',
  'webdav_desc': 'Connect your own WebDAV server (Nextcloud, Koofr, Synology...) — no developer registration, and the backup is encrypted on your phone before upload so the server never sees its contents.',
  'webdav_url': 'WebDAV folder URL',
  'webdav_username': 'Username',
  'webdav_password': 'Password',
  'webdav_encrypt': 'Encrypt backup before upload',
  'webdav_encrypt_hint': 'The stored backup can only be opened with this passphrase — keep it somewhere safe',
  'webdav_passphrase': 'Encryption passphrase',
  'webdav_save_test': 'Save & test connection',
  'webdav_test_ok': 'Connection OK — settings saved',
  'webdav_test_fail': 'Connection failed: {error}',
  'webdav_edit': 'Edit settings',
  'webdav_remove': 'Remove setup',
  'webdav_last_sync': 'Last sync: {date}',
  'webdav_encrypted_badge': 'Encrypted',
  'webdav_never_synced': 'Never synced yet',
  'webdav_what_is_title': 'What is WebDAV?',
  'webdav_what_is_body': 'WebDAV is a standard cloud-storage protocol supported by many services: a personal Nextcloud server, Koofr, Synology, and more. Create a folder on the service you prefer, enter its URL and your credentials here, and the app will upload a fully encrypted backup and restore it on any device — with no developer account at any provider.',
  'webdav_synced': 'Synced successfully',
  'webdav_restored': 'Backup restored',
  'webdav_no_backup_restore': 'No backup on the server yet',
  'webdav_wrong_passphrase': 'Wrong encryption passphrase',
};
