// Database migration tests — the data-preservation guarantee.
//
// Recreates the pre-1.3.0 (v2) schema exactly as shipped, seeds it with
// old-style rows, then runs the production v3 migration and verifies that
// every existing row survives untouched and new columns get safe defaults.
//
// Uses sqflite_common_ffi (SQLite on the host) — the same factory the app
// uses on desktop — so the SQL under test is real, not mocked.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/database/database_helper.dart';
import 'package:glucotrack/models/health_metric.dart';
import 'package:glucotrack/models/medication_info.dart';
import 'package:glucotrack/models/reading.dart';
import 'package:glucotrack/models/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  /// Opens an in-memory database and lays down the exact v2 (1.2.x) schema.
  Future<Database> openV2Database() async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await DatabaseHelper.createSchemaV2(db);
    return db;
  }

  group('v2 → v3 migration preserves user data', () {
    test('all existing readings survive the migration', () async {
      final db = await openV2Database();
      const oldReadings = [
        {
          'id': 'r1',
          'value': 120,
          'type': 'fasting',
          'timestamp': 1704067200000,
          'notes': 'صباح',
          'carbs': null,
          'insulin': null,
        },
        {
          'id': 'r2',
          'value': 210,
          'type': 'after_meal',
          'timestamp': 1704070800000,
          'notes': null,
          'carbs': 60,
          'insulin': 8,
        },
        {
          'id': 'r3',
          'value': 95,
          'type': 'before_sleep',
          'timestamp': 1704106800000,
          'notes': null,
          'carbs': null,
          'insulin': null,
        },
      ];
      for (final r in oldReadings) {
        await db.insert('readings', r);
      }

      await DatabaseHelper.migrateToV3(db);

      final rows = await db.query('readings', orderBy: 'id ASC');
      expect(rows.length, 3);
      expect(rows[0]['id'], 'r1');
      expect(rows[0]['value'], 120);
      expect(rows[0]['notes'], 'صباح');
      expect(rows[1]['value'], 210);
      expect(rows[1]['carbs'], 60);
      expect(rows[1]['insulin'], 8);
      expect(rows[2]['value'], 95);

      await db.close();
    });

    test(
      'existing reminders survive and default to measurement kind',
      () async {
        final db = await openV2Database();
        // Old rows have NO kind column — exactly what v1.2.x wrote.
        await db.insert('reminders', {
          'id': 'rem1',
          'time': '07:30',
          'label': 'قياس الصباح',
          'type': 'fasting',
          'enabled': 1,
        });
        await db.insert('reminders', {
          'id': 'rem2',
          'time': '22:00',
          'label': 'قبل النوم',
          'type': 'before_sleep',
          'enabled': 0,
        });

        await DatabaseHelper.migrateToV3(db);

        final rows = await db.query('reminders', orderBy: 'time ASC');
        expect(rows.length, 2, reason: 'No reminder row may be lost');
        expect(rows[0]['label'], 'قياس الصباح');
        expect(
          rows[0]['kind'],
          'measurement',
          reason: 'Existing reminders must keep their old meaning',
        );
        expect(rows[1]['enabled'], 0);

        // The Reminder model reads migrated rows the same way the app does.
        final reminders = rows.map(Reminder.fromDb).toList();
        expect(reminders[0].kind, ReminderKind.measurement);
        expect(reminders[0].enabled, isTrue);

        await db.close();
      },
    );

    test('existing settings survive with height_cm nullable', () async {
      final db = await openV2Database();
      await db.insert('settings', {
        'id': 1,
        'language': 'ar',
        'theme': 'modern',
        'diabetes_type': 'type1',
        'target_min': 90,
        'target_max': 200,
        'unit': 'mmol_L',
        'user_name': 'وسام',
        'onboarded': 1,
      });

      await DatabaseHelper.migrateToV3(db);

      final rows = await db.query('settings', where: 'id = 1');
      expect(rows.length, 1);
      final row = rows.first;
      expect(row['user_name'], 'وسام');
      expect(row['theme'], 'modern');
      expect(row['target_min'], 90);
      expect(row['target_max'], 200);
      expect(
        row['onboarded'],
        1,
        reason: 'Onboarded users must not see onboarding again',
      );
      expect(row['height_cm'], isNull);

      await db.close();
    });

    test('new v3 tables accept rows after the migration', () async {
      final db = await openV2Database();
      await DatabaseHelper.migrateToV3(db);

      final metric = HealthMetric(
        id: 'm1',
        weightKg: 82.5,
        systolic: 128,
        diastolic: 82,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1704067200000),
      );
      await db.insert('health_metrics', metric.toDb());
      await db.insert('water_log', {'date': '2026-09-12', 'cups': 5});

      final metricRows = await db.query('health_metrics');
      expect(metricRows.length, 1);
      expect(HealthMetric.fromDb(metricRows.first).weightKg, 82.5);

      final waterRows = await db.query('water_log');
      expect(WaterEntry.fromDb(waterRows.first).cups, 5);

      await db.close();
    });
  });

  group('fresh install path (v2 schema + migrations)', () {
    test('onCreate-equivalent path produces a working v6 database', () async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 6,
          onCreate: (db, version) async {
            await DatabaseHelper.createSchemaV2(db);
            await DatabaseHelper.migrateToV3(db);
            await DatabaseHelper.migrateToV4(db);
            await DatabaseHelper.migrateToV5(db);
            await DatabaseHelper.migrateToV6(db);
          },
        ),
      );

      // Every table is usable end-to-end on a fresh install.
      await db.insert('readings', {
        'id': 'r1',
        'value': 110,
        'type': 'fasting',
        'timestamp': 1704067200000,
        'notes': null,
        'carbs': null,
        'insulin': null,
      });
      await db.insert('reminders', {
        'id': 'rem1',
        'time': '08:00',
        'label': 'قياس',
        'type': 'fasting',
        'enabled': 1,
        'kind': 'medication',
      });
      await db.insert('settings', {
        'id': 1,
        'language': 'ar',
        'theme': 'classic',
        'diabetes_type': 'type2',
        'target_min': 80,
        'target_max': 180,
        'unit': 'mg_dL',
        'user_name': '',
        'onboarded': 0,
        'height_cm': 175.0,
        'uses_insulin': 1,
      });
      await db.insert(
        'health_metrics',
        HealthMetric(
          id: 'm1',
          weightKg: 70.0,
          timestamp: DateTime(2026, 9, 12),
        ).toDb(),
      );
      await db.insert('water_log', {'date': '2026-09-12', 'cups': 3});
      await db.insert(
        'medication_log',
        MedicationLogEntry(
          id: 'log1',
          reminderId: 'rem1',
          takenAt: DateTime(2026, 9, 12, 8),
        ).toDb(),
      );
      await db.insert('medication_cache', {
        'source': 'saudi',
        'rxcui': 'saudi:panadol',
        'name': 'Panadol',
        'synonym': 'بنادول',
        'dose_form': 'tablet',
        'strength': '500 mg',
        'tty': 'saudi',
        'fetched_at': 1700000000000,
      });

      expect((await db.query('readings')).length, 1);
      final rem = Reminder.fromDb((await db.query('reminders')).first);
      expect(rem.kind, ReminderKind.medication);
      final settingsRow = (await db.query('settings')).first;
      expect(settingsRow['height_cm'], 175.0);
      expect(settingsRow['uses_insulin'], 1);
      expect((await db.query('health_metrics')).length, 1);
      expect((await db.query('water_log')).length, 1);
      expect((await db.query('medication_log')).length, 1);
      expect((await db.query('medication_cache')).length, 1);

      await db.close();
    });
  });

  group('v5 → v6 medication cache migration', () {
    test('cache is recreated with a composite (source, rxcui) key', () async {
      final db = await openV2Database();
      await DatabaseHelper.migrateToV3(db);
      await DatabaseHelper.migrateToV4(db);
      await DatabaseHelper.migrateToV5(db);
      // Old single-PK row (v5 shape).
      await db.insert('medication_cache', {
        'rxcui': '5640',
        'name': 'ibuprofen',
        'fetched_at': 1700000000000,
      });

      await DatabaseHelper.migrateToV6(db);

      // Recreated table accepts multi-source rows keyed by (source, rxcui).
      await db.insert('medication_cache', {
        'source': 'rxnorm',
        'rxcui': '5640',
        'name': 'ibuprofen',
        'fetched_at': 1700000000000,
      });
      await db.insert('medication_cache', {
        'source': 'saudi',
        'rxcui': '5640',
        'name': 'same-id-different-source',
        'fetched_at': 1700000000000,
      });
      final rows = await db.query('medication_cache');
      expect(
        rows.length,
        2,
        reason: 'same rxcui under different sources coexists',
      );

      final info = MedicationInfo.fromDb(rows.first);
      expect(info.source, 'rxnorm');
      await db.close();
    });

    test('reminder dose fields survive v5/v6 with safe defaults', () async {
      final db = await openV2Database();
      await DatabaseHelper.migrateToV3(db);
      await DatabaseHelper.migrateToV4(db);
      await db.insert('reminders', {
        'id': 'rem1',
        'time': '08:00',
        'label': 'بنادول',
        'type': 'other',
        'enabled': 1,
        'kind': 'medication',
        'days_mask': 127,
      });

      await DatabaseHelper.migrateToV5(db);
      await DatabaseHelper.migrateToV6(db);

      final r = Reminder.fromDb((await db.query('reminders')).first);
      expect(r.doseForm, isNull);
      expect(r.doseAmount, isNull);
      expect(r.rxcui, isNull);

      await db.close();
    });
  });

  group('v3 → v4 migration preserves user data', () {
    test('reminders keep meaning; days_mask defaults to every day', () async {
      final db = await openV2Database();
      await DatabaseHelper.migrateToV3(db);
      await db.insert('reminders', {
        'id': 'rem1',
        'time': '20:00',
        'label': 'ميتفورمين · 500 ملغ',
        'type': 'other',
        'enabled': 1,
        'kind': 'medication',
      });

      await DatabaseHelper.migrateToV4(db);

      final r = Reminder.fromDb((await db.query('reminders')).first);
      expect(r.kind, ReminderKind.medication);
      expect(
        r.daysMask,
        WeekdayBits.everyDay,
        reason: 'Pre-v4 reminders must keep firing every day',
      );
      expect(r.effectiveTimes, ['20:00']);
      expect(r.timesPerDay, 1);

      await db.close();
    });

    test(
      'settings keep uses_insulin = 0 and medication_log is usable',
      () async {
        final db = await openV2Database();
        await DatabaseHelper.migrateToV3(db);
        await db.insert('settings', {
          'id': 1,
          'language': 'en',
          'theme': 'elder',
          'diabetes_type': 'type1',
          'target_min': 80,
          'target_max': 180,
          'unit': 'mg_dL',
          'user_name': 'Wissam',
          'onboarded': 1,
        });

        await DatabaseHelper.migrateToV4(db);

        final settingsRow = (await db.query('settings')).first;
        expect(settingsRow['user_name'], 'Wissam');
        expect(settingsRow['uses_insulin'], 0);

        await db.insert(
          'medication_log',
          MedicationLogEntry(
            id: 'log1',
            reminderId: 'remX',
            takenAt: DateTime(2026, 9, 12, 21, 30),
          ).toDb(),
        );
        final log = await db.query('medication_log');
        expect(log.length, 1);
        expect(MedicationLogEntry.fromDb(log.first).takenAt.hour, 21);

        await db.close();
      },
    );
  });

  // ── Reminder model backward compatibility (old backups / DB rows) ────────
  group('Reminder.fromDb kind defaults', () {
    test('row without kind (old data) reads as measurement', () {
      final r = Reminder.fromDb({
        'id': 'rem1',
        'time': '07:30',
        'label': 'قياس',
        'type': 'fasting',
        'enabled': 1,
      });
      expect(r.kind, ReminderKind.measurement);
    });

    test('row with medication kind round-trips losslessly', () {
      const original = Reminder(
        id: 'rem2',
        time: '09:00',
        label: 'ميتفورمين · 500 ملغ',
        type: ReadingType.other,
        enabled: true,
        kind: ReminderKind.medication,
      );
      final restored = Reminder.fromDb(original.toDb());
      expect(restored.kind, ReminderKind.medication);
      expect(restored.label, 'ميتفورمين · 500 ملغ');
      expect(restored.enabled, isTrue);
    });

    test('copyWith keeps kind unless changed', () {
      const original = Reminder(
        id: 'rem1',
        time: '08:00',
        label: 'x',
        type: ReadingType.fasting,
        enabled: true,
      );
      expect(original.kind, ReminderKind.measurement);
      expect(original.copyWith(enabled: false).kind, ReminderKind.measurement);
      expect(
        original.copyWith(kind: ReminderKind.medication).kind,
        ReminderKind.medication,
      );
    });
  });
}
