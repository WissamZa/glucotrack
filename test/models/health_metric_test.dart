// Tests for the health-metrics model — DB round-trip, BMI classification,
// and water-log date keys.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/health_metric.dart';

void main() {
  group('HealthMetric DB serialization', () {
    test('full entry round-trips losslessly', () {
      final original = HealthMetric(
        id: 'hm1',
        weightKg: 82.5,
        systolic: 125,
        diastolic: 80,
        timestamp: DateTime.utc(2026, 9, 12, 9, 30),
      );
      final restored = HealthMetric.fromDb(original.toDb());
      expect(restored.id, original.id);
      expect(restored.weightKg, 82.5);
      expect(restored.systolic, 125);
      expect(restored.diastolic, 80);
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
    });

    test('weight-only and BP-only entries round-trip with nulls', () {
      final weightOnly = HealthMetric(
        id: 'hm2',
        weightKg: 71.0,
        timestamp: DateTime(2026, 1, 1),
      );
      final w = HealthMetric.fromDb(weightOnly.toDb());
      expect(w.weightKg, 71.0);
      expect(w.systolic, isNull);
      expect(w.diastolic, isNull);

      final bpOnly = HealthMetric(
        id: 'hm3',
        systolic: 118,
        diastolic: 76,
        timestamp: DateTime(2026, 1, 2),
      );
      final b = HealthMetric.fromDb(bpOnly.toDb());
      expect(b.weightKg, isNull);
      expect(b.systolic, 118);
      expect(b.diastolic, 76);
    });

    test('copyWith distinguishes "not supplied" from "explicitly null"', () {
      final m = HealthMetric(
        id: 'hm4',
        weightKg: 90.0,
        systolic: 130,
        diastolic: 85,
        timestamp: DateTime(2026, 1, 3),
      );
      // Not supplied → keep.
      expect(m.copyWith().weightKg, 90.0);
      // Explicitly null → clear.
      expect(m.copyWith(weightKg: null).weightKg, isNull);
      expect(m.copyWith(systolic: null, diastolic: null).systolic, isNull);
      expect(m.copyWith(weightKg: 88.5).weightKg, 88.5);
    });
  });

  group('BmiCalculator', () {
    test('returns null when height or weight is missing', () {
      expect(BmiCalculator.compute(weightKg: 80, heightCm: null), isNull);
      expect(BmiCalculator.compute(weightKg: null, heightCm: 175), isNull);
    });

    test('returns null for implausible values', () {
      expect(BmiCalculator.compute(weightKg: 5, heightCm: 175), isNull);
      expect(BmiCalculator.compute(weightKg: 80, heightCm: 10), isNull);
      expect(BmiCalculator.compute(weightKg: 80, heightCm: 400), isNull);
    });

    test('classic BMI values classify per WHO bands', () {
      // 70 kg / 1.75 m → 22.86 normal
      final normal = BmiCalculator.compute(weightKg: 70, heightCm: 175)!;
      expect(normal.value, closeTo(22.86, 0.01));
      expect(normal.category, BmiCategory.normal);

      // 50 kg / 1.75 m → 16.33 underweight
      expect(
        BmiCalculator.compute(weightKg: 50, heightCm: 175)!.category,
        BmiCategory.underweight,
      );

      // 85 kg / 1.75 m → 27.76 overweight
      expect(
        BmiCalculator.compute(weightKg: 85, heightCm: 175)!.category,
        BmiCategory.overweight,
      );

      // 100 kg / 1.70 m → 34.6 obese
      expect(
        BmiCalculator.compute(weightKg: 100, heightCm: 170)!.category,
        BmiCategory.obese,
      );
    });

    test('band boundaries are exact', () {
      // 18.5 exactly → normal; 24.9 → normal; 25 → overweight; 30 → obese
      expect(BmiCalculator.categorize(18.4), BmiCategory.underweight);
      expect(BmiCalculator.categorize(18.5), BmiCategory.normal);
      expect(BmiCalculator.categorize(24.9), BmiCategory.normal);
      expect(BmiCalculator.categorize(25.0), BmiCategory.overweight);
      expect(BmiCalculator.categorize(29.9), BmiCategory.overweight);
      expect(BmiCalculator.categorize(30.0), BmiCategory.obese);
    });
  });

  group('WaterEntry', () {
    test('dateKey formats zero-padded yyyy-MM-dd', () {
      expect(WaterEntry.dateKey(DateTime(2026, 9, 12)), '2026-09-12');
      expect(WaterEntry.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('DB round-trip', () {
      const original = WaterEntry(date: '2026-09-12', cups: 6);
      final restored = WaterEntry.fromDb(original.toDb());
      expect(restored.date, '2026-09-12');
      expect(restored.cups, 6);
    });

    test('daily goal is defined', () {
      expect(WaterEntry.dailyGoal, greaterThan(0));
    });
  });
}
