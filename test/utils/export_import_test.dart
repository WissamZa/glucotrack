// Tests for export/import utilities — CSV injection, JSON round-trip, schema validation
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/health_metric.dart';
import 'package:glucotrack/models/reading.dart';
import 'package:glucotrack/models/reminder.dart';
import 'package:glucotrack/utils/export_import.dart';

void main() {
  group('CSV export', () {
    test('escapes formula injection attempts (=, +, -, @)', () {
      final readings = [
        Reading(
          id: 'r1',
          value: 120,
          type: ReadingType.fasting,
          timestamp: DateTime(2024, 1, 1),
          notes: '=CMD("calc.exe")',
        ),
        Reading(
          id: 'r2',
          value: 130,
          type: ReadingType.beforeMeal,
          timestamp: DateTime(2024, 1, 2),
          notes: '+hidden_formula',
        ),
        Reading(
          id: 'r3',
          value: 140,
          type: ReadingType.afterMeal,
          timestamp: DateTime(2024, 1, 3),
          notes: '-another_injection',
        ),
        Reading(
          id: 'r4',
          value: 150,
          type: ReadingType.other,
          timestamp: DateTime(2024, 1, 4),
          notes: '@injection',
        ),
      ];
      final csv = DataExporter.exportReadingsToCsv(readings);

      expect(csv, contains("'=CMD"));
      expect(csv, contains("'+hidden"));
      expect(csv, contains("'-another"));
      expect(csv, contains("'@injection"));
      expect(csv, isNot(contains(',=CMD')));
    });

    test('doubles embedded double quotes per RFC 4180', () {
      final readings = [
        Reading(
          id: 'r1',
          value: 120,
          type: ReadingType.fasting,
          timestamp: DateTime(2024, 1, 1),
          notes: 'He said "hi"',
        ),
      ];
      final csv = DataExporter.exportReadingsToCsv(readings);
      expect(csv, contains('"He said ""hi"""'));
    });

    test('handles empty notes', () {
      final readings = [
        Reading(
          id: 'r1',
          value: 120,
          type: ReadingType.fasting,
          timestamp: DateTime(2024, 1, 1),
          notes: null,
        ),
      ];
      final csv = DataExporter.exportReadingsToCsv(readings);
      expect(csv, contains(',"",'));
    });

    test('header row is RFC 4180 compliant', () {
      final csv = DataExporter.exportReadingsToCsv([]);
      final firstLine = csv.split('\n').first;
      expect(firstLine, contains('"ID"'));
      expect(firstLine, contains('"Value (mg/dL)"'));
    });
  });

  group('JSON import validation', () {
    test('returns success for valid export', () {
      final json = jsonEncode({
        'version': '1.1.0',
        'exportedAt': '2024-01-01T00:00:00.000',
        'readings': [
          {
            'id': 'r1',
            'value': 120,
            'type': 'fasting',
            'timestamp': 1704067200000,
            'notes': 'test',
            'carbs': null,
            'insulin': null,
          },
        ],
        'reminders': [],
      });

      final result = DataExporter.importFromJson(json);
      expect(result.success, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.readings.length, 1);
      expect(result.data!.readings[0].value, 120);
      expect(result.data!.readings[0].notes, 'test');
    });

    test('returns failure for invalid JSON', () {
      final result = DataExporter.importFromJson('not valid json {');
      expect(result.success, isFalse);
      expect(result.error, contains('Invalid JSON'));
    });

    test('returns failure for missing version field', () {
      final json = jsonEncode({
        'readings': [],
        'reminders': [],
        'exportedAt': '2024-01-01T00:00:00.000',
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isFalse);
      expect(result.error, contains('version'));
    });

    test('returns failure for unsupported version', () {
      final json = jsonEncode({
        'version': '2.0.0',
        'readings': [],
        'reminders': [],
        'exportedAt': '2024-01-01T00:00:00.000',
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isFalse);
      expect(result.error, contains('Unsupported version'));
    });

    test('returns failure when readings is not a list', () {
      final json = jsonEncode({
        'version': '1.1.0',
        'readings': 'not a list',
        'reminders': [],
        'exportedAt': '2024-01-01T00:00:00.000',
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isFalse);
      expect(result.error, contains('readings'));
    });

    test('returns failure when reminders is not a list', () {
      final json = jsonEncode({
        'version': '1.1.0',
        'readings': [],
        'reminders': 'not a list',
        'exportedAt': '2024-01-01T00:00:00.000',
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isFalse);
      expect(result.error, contains('reminders'));
    });

    test('returns failure for non-object JSON', () {
      final result = DataExporter.importFromJson('[1, 2, 3]');
      expect(result.success, isFalse);
      expect(result.error, contains('not a JSON object'));
    });
  });

  group('JSON round-trip with Arabic text', () {
    test('preserves Arabic notes through export-import cycle', () {
      final original = ExportData(
        readings: [
          Reading(
            id: 'r1',
            value: 120,
            type: ReadingType.afterMeal,
            timestamp: DateTime(2024, 6, 15, 14, 30),
            notes: 'مرتفع بعد الغداء',
            carbs: 60,
            insulin: 10,
          ),
        ],
        reminders: [
          const Reminder(
            id: 'rem1',
            time: '08:00',
            label: 'صباحاً',
            type: ReadingType.fasting,
            enabled: true,
          ),
        ],
        exportedAt: DateTime(2024, 6, 15),
      );

      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(original.toJson());
      final result = DataExporter.importFromJson(jsonStr);

      expect(result.success, isTrue);
      expect(result.data!.readings.length, 1);
      expect(
        result.data!.readings[0].notes,
        'مرتفع بعد الغداء',
        reason: 'Arabic text must survive round-trip',
      );
      expect(result.data!.readings[0].carbs, 60);
      expect(result.data!.readings[0].insulin, 10);
      expect(result.data!.reminders.length, 1);
      expect(result.data!.reminders[0].label, 'صباحاً');
    });

    test('preserves multiple readings with mixed Arabic and English', () {
      final original = ExportData(
        readings: [
          Reading(
            id: 'r1',
            value: 100,
            type: ReadingType.fasting,
            timestamp: DateTime(2024, 1, 1, 8, 0),
            notes: 'Fasting morning',
          ),
          Reading(
            id: 'r2',
            value: 180,
            type: ReadingType.afterMeal,
            timestamp: DateTime(2024, 1, 1, 13, 0),
            notes: 'بعد الغداء',
          ),
          Reading(
            id: 'r3',
            value: 140,
            type: ReadingType.beforeSleep,
            timestamp: DateTime(2024, 1, 1, 22, 0),
            notes: null,
          ),
        ],
        reminders: [],
        exportedAt: DateTime(2024, 1, 1),
      );

      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(original.toJson());
      final result = DataExporter.importFromJson(jsonStr);

      expect(result.success, isTrue);
      expect(result.data!.readings.length, 3);
      expect(result.data!.readings[0].notes, 'Fasting morning');
      expect(result.data!.readings[1].notes, 'بعد الغداء');
      expect(result.data!.readings[2].notes, isNull);
    });
  });

  group('v1.3 export schema (health metrics + water)', () {
    test('old (pre-1.3) backups import fine — new fields default to empty', () {
      // A real v1.2.x backup: no healthMetrics / waterLog keys at all.
      final json = jsonEncode({
        'version': '1.2.0',
        'exportedAt': '2024-01-01T00:00:00.000',
        'readings': [],
        'reminders': [],
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isTrue);
      expect(result.data!.healthMetrics, isEmpty);
      expect(result.data!.waterLog, isEmpty);
    });

    test('old reminders without kind import as measurement reminders', () {
      final json = jsonEncode({
        'version': '1.2.0',
        'exportedAt': '2024-01-01T00:00:00.000',
        'readings': [],
        'reminders': [
          {
            'id': 'rem1',
            'time': '08:00',
            'label': 'قياس',
            'type': 'fasting',
            'enabled': 1,
          },
        ],
      });
      final result = DataExporter.importFromJson(json);
      expect(result.success, isTrue);
      expect(result.data!.reminders.first.kind, ReminderKind.measurement);
    });

    test('new round-trip carries health metrics and water log', () {
      final original = ExportData(
        readings: [],
        reminders: [],
        healthMetrics: [
          HealthMetric(
            id: 'hm1',
            weightKg: 84.2,
            systolic: 122,
            diastolic: 79,
            timestamp: DateTime(2026, 9, 1),
          ),
        ],
        waterLog: const [WaterEntry(date: '2026-09-11', cups: 7)],
        exportedAt: DateTime(2026, 9, 12),
      );

      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(original.toJson());
      final result = DataExporter.importFromJson(jsonStr);

      expect(result.success, isTrue);
      expect(result.data!.healthMetrics.length, 1);
      expect(result.data!.healthMetrics.first.weightKg, 84.2);
      expect(result.data!.healthMetrics.first.systolic, 122);
      expect(result.data!.waterLog.length, 1);
      expect(result.data!.waterLog.first.cups, 7);
    });

    test('v1.3 round-trip keeps medication reminder kind', () {
      final original = ExportData(
        readings: [],
        reminders: const [
          Reminder(
            id: 'rem2',
            time: '09:00',
            label: 'ميتفورمين · 500 ملغ',
            type: ReadingType.other,
            enabled: true,
            kind: ReminderKind.medication,
          ),
        ],
        exportedAt: DateTime(2026, 9, 12),
      );

      final jsonStr = const JsonEncoder.withIndent('  ')
          .convert(original.toJson());
      final result = DataExporter.importFromJson(jsonStr);

      expect(result.success, isTrue);
      expect(result.data!.reminders.first.kind, ReminderKind.medication);
      expect(result.data!.reminders.first.label, 'ميتفورمين · 500 ملغ');
    });
  });
}
