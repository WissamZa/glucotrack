// Unit tests for the Reading model.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/reading.dart';

void main() {
  group('Reading model', () {
    final sampleReading = Reading(
      id: 'test-1',
      value: 120,
      type: ReadingType.fasting,
      timestamp: _epoch,
    );

    // ── status() ───────────────────────────────────────────────────────────
    group('status()', () {
      test('returns criticalLow when value < 54', () {
        final r = Reading(
            id: 'x', value: 50, type: ReadingType.fasting, timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.criticalLow);
      });

      test('returns low when value is between 54 and targetMin', () {
        final r = Reading(
            id: 'x', value: 70, type: ReadingType.fasting, timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.low);
      });

      test('returns inRange when value is within target range', () {
        final r = Reading(
            id: 'x',
            value: 120,
            type: ReadingType.afterMeal,
            timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.inRange);
      });

      test('returns inRange at exact targetMin', () {
        final r = Reading(
            id: 'x', value: 80, type: ReadingType.fasting, timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.inRange);
      });

      test('returns inRange at exact targetMax', () {
        final r = Reading(
            id: 'x',
            value: 180,
            type: ReadingType.afterMeal,
            timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.inRange);
      });

      test('returns high when value > targetMax and <= 250', () {
        final r = Reading(
            id: 'x',
            value: 220,
            type: ReadingType.afterMeal,
            timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.high);
      });

      test('returns criticalHigh when value > 250', () {
        final r = Reading(
            id: 'x',
            value: 300,
            type: ReadingType.afterMeal,
            timestamp: _epoch);
        expect(r.status(80, 180), ReadingStatus.criticalHigh);
      });
    });

    // ── copyWith() ─────────────────────────────────────────────────────────
    group('copyWith()', () {
      test('returns identical object when no overrides', () {
        final copy = sampleReading.copyWith();
        expect(copy.id, sampleReading.id);
        expect(copy.value, sampleReading.value);
        expect(copy.type, sampleReading.type);
        expect(copy.timestamp, sampleReading.timestamp);
      });

      test('overrides individual fields', () {
        final copy =
            sampleReading.copyWith(value: 200, type: ReadingType.afterMeal);
        expect(copy.id, sampleReading.id);
        expect(copy.value, 200);
        expect(copy.type, ReadingType.afterMeal);
        expect(copy.timestamp, sampleReading.timestamp);
      });

      test('preserves optional fields as null when not set', () {
        expect(sampleReading.notes, isNull);
        expect(sampleReading.carbs, isNull);
        expect(sampleReading.insulin, isNull);
      });

      test('sets optional fields correctly', () {
        final copy =
            sampleReading.copyWith(notes: 'Test note', carbs: 30, insulin: 4);
        expect(copy.notes, 'Test note');
        expect(copy.carbs, 30);
        expect(copy.insulin, 4);
      });
    });

    // ── toDb / fromDb round-trip ────────────────────────────────────────────
    group('DB serialisation', () {
      test('toDb produces correct keys', () {
        final map = sampleReading.toDb();
        expect(map['id'], 'test-1');
        expect(map['value'], 120);
        expect(map['type'], 'fasting');
        expect(map['timestamp'], _epoch.millisecondsSinceEpoch);
      });

      test('fromDb restores all fields', () {
        final map = sampleReading.toDb();
        final restored = Reading.fromDb(map);
        expect(restored.id, sampleReading.id);
        expect(restored.value, sampleReading.value);
        expect(restored.type, sampleReading.type);
        expect(restored.timestamp.millisecondsSinceEpoch,
            sampleReading.timestamp.millisecondsSinceEpoch);
      });

      test('round-trip preserves optional fields', () {
        final r = Reading(
          id: 'test-2',
          value: 150,
          type: ReadingType.afterMeal,
          timestamp: _epoch,
          notes: 'After lunch',
          carbs: 45,
          insulin: 6,
        );
        final restored = Reading.fromDb(r.toDb());
        expect(restored.notes, 'After lunch');
        expect(restored.carbs, 45);
        expect(restored.insulin, 6);
      });
    });

    // ── ReadingTypeX ────────────────────────────────────────────────────────
    group('ReadingTypeX', () {
      test('dbValue maps all types correctly', () {
        expect(ReadingType.fasting.dbValue, 'fasting');
        expect(ReadingType.beforeMeal.dbValue, 'before_meal');
        expect(ReadingType.afterMeal.dbValue, 'after_meal');
        expect(ReadingType.beforeSleep.dbValue, 'before_sleep');
        expect(ReadingType.afterExercise.dbValue, 'after_exercise');
        expect(ReadingType.other.dbValue, 'other');
      });

      test('fromDb maps all strings correctly', () {
        expect(ReadingTypeX.fromDb('fasting'), ReadingType.fasting);
        expect(ReadingTypeX.fromDb('before_meal'), ReadingType.beforeMeal);
        expect(ReadingTypeX.fromDb('after_meal'), ReadingType.afterMeal);
        expect(ReadingTypeX.fromDb('before_sleep'), ReadingType.beforeSleep);
        expect(
            ReadingTypeX.fromDb('after_exercise'), ReadingType.afterExercise);
        expect(ReadingTypeX.fromDb('other'), ReadingType.other);
      });

      test('fromDb falls back to other for unknown strings', () {
        expect(ReadingTypeX.fromDb('unknown_type'), ReadingType.other);
      });
    });

    // ── copyWith nullable-field clearing (FIX-002) ─────────────────────────
    test('copyWith clears nullable fields when null is explicitly passed', () {
      final original = Reading(
        id: 'r1',
        value: 120,
        type: ReadingType.beforeMeal,
        timestamp: DateTime(2024, 1, 1, 8, 0),
        notes: 'High after lunch',
        carbs: 45,
        insulin: 10,
      );

      final cleared = original.copyWith(
        notes: null,
        carbs: null,
        insulin: null,
      );

      expect(cleared.notes, isNull, reason: 'notes should be cleared');
      expect(cleared.carbs, isNull, reason: 'carbs should be cleared');
      expect(cleared.insulin, isNull, reason: 'insulin should be cleared');
      expect(cleared.value, 120, reason: 'non-cleared fields retained');
    });

    test('copyWith retains fields when not provided', () {
      final original = Reading(
        id: 'r1', value: 120, type: ReadingType.fasting,
        timestamp: DateTime(2024, 1, 1),
        notes: 'original', carbs: 30, insulin: 5,
      );
      final updated = original.copyWith(value: 130);
      expect(updated.value, 130);
      expect(updated.notes, 'original');
      expect(updated.carbs, 30);
    });
  });
}

// Use a fixed epoch for deterministic tests.
final _epoch = DateTime.utc(2024, 6, 15, 8, 0);
