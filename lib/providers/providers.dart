// App-wide providers: Readings, Reminders, HealthMetrics + sort order.
//
// Uses Provider for state management. All DB mutations go through these
// providers and notify listeners automatically.
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../i18n/strings.dart';
import '../models/health_metric.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../models/settings.dart';
import '../services/notification_service.dart';

// ===== Readings Provider =====
class ReadingsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<Reading> _readings = [];
  SortOrder _sort = SortOrder.newest;

  List<Reading> get readings => _sorted(_readings);
  List<Reading> get rawReadings => List.unmodifiable(_readings);
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
    // Binary search for insertion index (readings are sorted DESC by timestamp)
    var lo = 0, hi = _readings.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_readings[mid].timestamp.compareTo(r.timestamp) > 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    _readings.insert(lo, r);
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
  final _notif = NotificationService();
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
    if (r.enabled) {
      await _scheduleNotification(r);
    }
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
    if (updated.enabled) {
      await _scheduleNotification(updated);
    } else {
      await _notif.cancelReminder(id.hashCode);
    }
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _db.deleteReminder(id);
    await _notif.cancelReminder(id.hashCode);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> _scheduleNotification(Reminder r) async {
    final parts = r.time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;
    final isMedication = r.kind == ReminderKind.medication;
    await _notif.scheduleDailyReminder(
      id: r.id.hashCode,
      hour: hour,
      minute: minute,
      title: 'GlucoTrack',
      body: r.label.isEmpty
          ? (isMedication
                ? 'Time to take your medication'
                : 'Time to measure your blood glucose')
          : r.label,
      medication: isMedication,
    );
  }
}

// ===== Health metrics provider (weight / BP / water) =====
class HealthMetricsProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  List<HealthMetric> _metrics = [];
  final Map<String, int> _waterByDate = {};

  List<HealthMetric> get metrics => List.unmodifiable(_metrics);
  HealthMetric? get latest => _metrics.isEmpty ? null : _metrics.first;

  int cupsForDate(String dateKey) => _waterByDate[dateKey] ?? 0;
  int get cupsToday => cupsForDate(WaterEntry.dateKey(DateTime.now()));

  /// Full water history (newest first) — used by JSON export.
  List<WaterEntry> get waterLog {
    final keys = _waterByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .map((k) => WaterEntry(date: k, cups: _waterByDate[k]!))
        .toList();
  }

  /// Last 7 days (oldest → newest) for the mini chart on Home.
  List<WaterEntry> get last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = WaterEntry.dateKey(d);
      return WaterEntry(date: key, cups: _waterByDate[key] ?? 0);
    });
  }

  Future<void> load() async {
    _metrics = await _db.getHealthMetrics();
    final water = await _db.getWaterLog();
    _waterByDate
      ..clear()
      ..addEntries(water.map((e) => MapEntry(e.date, e.cups)));
    notifyListeners();
  }

  Future<void> addMetric(HealthMetric m) async {
    await _db.insertHealthMetric(m);
    _metrics.insert(0, m);
    // Entries are loaded DESC by timestamp; keep that invariant.
    _metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> removeMetric(String id) async {
    await _db.deleteHealthMetric(id);
    _metrics.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> _addCups(String dateKey, int delta) async {
    await setWater(dateKey, cupsForDate(dateKey) + delta);
  }

  /// Set the cup count for [dateKey] (clamped 0–50) — also used by JSON
  /// import to restore/merge the water history.
  Future<void> setWater(String dateKey, int cups) async {
    final next = cups.clamp(0, 50);
    await _db.setWaterCups(dateKey, next);
    _waterByDate[dateKey] = next;
    notifyListeners();
  }

  Future<void> addCup() => _addCups(WaterEntry.dateKey(DateTime.now()), 1);
  Future<void> removeCup() => _addCups(WaterEntry.dateKey(DateTime.now()), -1);
}

// ===== Settings Provider persistence extension =====
// Extends SettingsProviderState (defined in i18n/strings.dart) with DB I/O.
extension SettingsProviderPersistence on SettingsProviderState {
  Future<void> loadFromDb() async {
    final row = await DatabaseHelper().getSettingsRow();
    if (row == null) return;
    update(
      Settings(
        language: (row['language'] as String) == 'ar'
            ? Language.ar
            : Language.en,
        theme: _themeFromString(row['theme'] as String),
        diabetesType: _dtypeFromString(row['diabetes_type'] as String),
        targetMin: row['target_min'] as int,
        targetMax: row['target_max'] as int,
        unit: (row['unit'] as String) == 'mg_dL'
            ? GlucoseUnit.mgDl
            : GlucoseUnit.mmolL,
        userName: (row['user_name'] as String?) ?? '',
        onboarded: (row['onboarded'] as int) == 1,
        heightCm: (row['height_cm'] as num?)?.toDouble(),
      ),
    );
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
      'height_cm': s.heightCm,
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
