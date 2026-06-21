// App-wide providers: Settings, Readings, Reminders, plus sort order.
//
// Uses Provider for state management. All DB mutations go through these
// providers and notify listeners automatically.
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../models/settings.dart';

// Re-export SettingsProvider from i18n/strings.dart for convenience
export '../i18n/strings.dart' show SettingsProvider, SettingsProviderState;

// ===== Readings Provider =====
class ReadingsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<Reading> _readings = [];
  SortOrder _sort = SortOrder.newest;

  List<Reading> get readings => _sorted(_readings);
  List<Reading> get rawReadings => _readings;
  SortOrder get sortOrder => _sort;

  void setSort(SortOrder s) {
    _sort = s;
    notifyListeners();
  }

  Future<void> load() async {
    _readings = await _db.getReadings();
    notifyListeners();
  }

  Future<void> add(Reading r) async {
    await _db.insertReading(r);
    _readings.insert(0, r);
    _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> update(Reading r) async {
    await _db.updateReading(r);
    final i = _readings.indexWhere((x) => x.id == r.id);
    if (i >= 0) _readings[i] = r;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _db.deleteReading(id);
    _readings.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Reading? findById(String id) {
    final i = _readings.indexWhere((r) => r.id == id);
    return i >= 0 ? _readings[i] : null;
  }

  List<Reading> _sorted(List<Reading> list) {
    final copy = List<Reading>.from(list);
    switch (_sort) {
      case SortOrder.newest:
        copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOrder.oldest:
        copy.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOrder.highest:
        copy.sort((a, b) => b.value.compareTo(a.value));
        break;
      case SortOrder.lowest:
        copy.sort((a, b) => a.value.compareTo(b.value));
        break;
    }
    return copy;
  }
}

// ===== Reminders Provider =====
class RemindersProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<Reminder> _reminders = [];

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  int get activeCount => _reminders.where((r) => r.enabled).length;

  Future<void> load() async {
    _reminders = await _db.getReminders();
    _reminders.sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  Future<void> add(Reminder r) async {
    await _db.insertReminder(r);
    _reminders.add(r);
    _reminders.sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  Future<void> update(Reminder r) async {
    await _db.updateReminder(r);
    final i = _reminders.indexWhere((x) => x.id == r.id);
    if (i >= 0) _reminders[i] = r;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    final i = _reminders.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final updated = _reminders[i].copyWith(enabled: !_reminders[i].enabled);
    await _db.updateReminder(updated);
    _reminders[i] = updated;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _db.deleteReminder(id);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

// ===== Settings Provider (extends the one in i18n/strings.dart) =====
extension SettingsProviderPersistence on SettingsProviderState {
  Future<void> loadFromDb() async {
    final row = await DatabaseHelper().getSettingsRow();
    if (row == null) return;
    update(Settings(
      language: (row['language'] as String) == 'ar' ? Language.ar : Language.en,
      theme: _themeFromString(row['theme'] as String),
      diabetesType: _dtypeFromString(row['diabetes_type'] as String),
      targetMin: row['target_min'] as int,
      targetMax: row['target_max'] as int,
      unit: (row['unit'] as String) == 'mg_dL' ? GlucoseUnit.mgDl : GlucoseUnit.mmolL,
      userName: (row['user_name'] as String?) ?? '',
      onboarded: (row['onboarded'] as int) == 1,
    ));
  }

  Future<void> persist(Settings s) async {
    await DatabaseHelper().upsertSettings({
      'language': s.language == Language.ar ? 'ar' : 'en',
      'theme': _themeToString(s.theme),
      'diabetes_type': _dtypeToString(s.diabetesType),
      'target_min': s.targetMin,
      'target_max': s.targetMax,
      'unit': s.unit == GlucoseUnit.mgDl ? 'mg_dL' : 'mmol_L',
      'user_name': s.userName,
      'onboarded': s.onboarded ? 1 : 0,
    });
    update(s);
  }

  Future<void> reset() async {
    await DatabaseHelper().upsertSettings({
      'language': 'ar',
      'theme': 'classic',
      'diabetes_type': 'type2',
      'target_min': 80,
      'target_max': 180,
      'unit': 'mg_dL',
      'user_name': '',
      'onboarded': 0,
    });
    update(const Settings());
  }
}

ThemeStyle _themeFromString(String s) {
  switch (s) {
    case 'modern':
      return ThemeStyle.modern;
    case 'elder':
      return ThemeStyle.elder;
    default:
      return ThemeStyle.classic;
  }
}

String _themeToString(ThemeStyle t) {
  switch (t) {
    case ThemeStyle.modern:
      return 'modern';
    case ThemeStyle.elder:
      return 'elder';
    case ThemeStyle.classic:
      return 'classic';
  }
}

DiabetesType _dtypeFromString(String s) {
  switch (s) {
    case 'type1':
      return DiabetesType.type1;
    case 'gestational':
      return DiabetesType.gestational;
    default:
      return DiabetesType.type2;
  }
}

String _dtypeToString(DiabetesType t) {
  switch (t) {
    case DiabetesType.type1:
      return 'type1';
    case DiabetesType.gestational:
      return 'gestational';
    case DiabetesType.type2:
      return 'type2';
  }
}
