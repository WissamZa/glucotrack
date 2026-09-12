// Health metrics — weight & blood-pressure entries plus the daily water log.
//
// Stored in the `health_metrics` and `water_log` tables introduced by the
// DatabaseHelper v3 schema. Both are additive to the v2 schema, so data from
// previous app versions is untouched.

/// Sentinel object used by [HealthMetric.copyWith] to distinguish
/// "argument not supplied" from "argument explicitly null".
class _UnsetMetric {
  const _UnsetMetric();
}

const _unsetMetric = _UnsetMetric();

/// A single weight and/or blood-pressure measurement. Any combination is
/// allowed: weight-only, BP-only, or both at once.
class HealthMetric {
  final String id;
  final double? weightKg;
  final int? systolic; // mmHg (upper value)
  final int? diastolic; // mmHg (lower value)
  final DateTime timestamp;

  const HealthMetric({
    required this.id,
    this.weightKg,
    this.systolic,
    this.diastolic,
    required this.timestamp,
  });

  Map<String, dynamic> toDb() => {
    'id': id,
    'weight_kg': weightKg,
    'systolic': systolic,
    'diastolic': diastolic,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory HealthMetric.fromDb(Map<String, dynamic> m) => HealthMetric(
    id: m['id'] as String,
    weightKg: (m['weight_kg'] as num?)?.toDouble(),
    systolic: m['systolic'] as int?,
    diastolic: m['diastolic'] as int?,
    timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
  );

  HealthMetric copyWith({
    Object? id = _unsetMetric,
    Object? weightKg = _unsetMetric,
    Object? systolic = _unsetMetric,
    Object? diastolic = _unsetMetric,
    Object? timestamp = _unsetMetric,
  }) => HealthMetric(
    id: identical(id, _unsetMetric) ? this.id : id as String,
    weightKg: identical(weightKg, _unsetMetric)
        ? this.weightKg
        : weightKg as double?,
    systolic: identical(systolic, _unsetMetric)
        ? this.systolic
        : systolic as int?,
    diastolic: identical(diastolic, _unsetMetric)
        ? this.diastolic
        : diastolic as int?,
    timestamp: identical(timestamp, _unsetMetric)
        ? this.timestamp
        : timestamp as DateTime,
  );
}

enum BmiCategory { underweight, normal, overweight, obese }

extension BmiCategoryX on BmiCategory {
  int get colorHex {
    switch (this) {
      case BmiCategory.underweight:
        return 0xFFF59E0B; // amber
      case BmiCategory.normal:
        return 0xFF10B981; // green
      case BmiCategory.overweight:
        return 0xFFF97316; // orange
      case BmiCategory.obese:
        return 0xFFEF4444; // red
    }
  }
}

/// Body Mass Index (weight in kg / height in m²) per WHO classification.
class BmiCalculator {
  /// Returns `null` when [heightCm] or [weightKg] is missing/out of range —
  /// BMI is only meaningful for plausible human values.
  static ({double value, BmiCategory category})? compute({
    required double? weightKg,
    required double? heightCm,
  }) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg < 20 || weightKg > 400) return null;
    if (heightCm < 80 || heightCm > 250) return null;
    final meters = heightCm / 100;
    final value = weightKg / (meters * meters);
    final category = categorize(value);
    return (value: value, category: category);
  }

  static BmiCategory categorize(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }
}

/// Daily water intake, persisted as one row per day.
class WaterEntry {
  final String date; // "yyyy-MM-dd"
  final int cups;

  const WaterEntry({required this.date, required this.cups});

  /// Default daily goal in cups (~2 L with a 250 ml cup).
  static const int dailyGoal = 8;

  Map<String, dynamic> toDb() => {'date': date, 'cups': cups};

  factory WaterEntry.fromDb(Map<String, dynamic> m) =>
      WaterEntry(date: m['date'] as String, cups: m['cups'] as int);

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
