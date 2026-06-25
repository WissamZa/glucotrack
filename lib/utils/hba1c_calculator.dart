// HbA1c estimation calculator
// Uses the standard ADAG formula: eAG (mg/dL) = (28.7 × HbA1c) − 46.7
// Inverse: HbA1c (%) = (eAG + 46.7) / 28.7
//
// Categories:
//   Normal:      < 5.7%
//   Prediabetes: 5.7% — 6.4%
//   Diabetes:    ≥ 6.5%
//
// Reference: American Diabetes Association (ADA)
import '../models/reading.dart';

class HbA1cResult {
  final double percentage;
  final double estimatedAverageGlucose; // mg/dL
  final HbA1cCategory category;

  const HbA1cResult({
    required this.percentage,
    required this.estimatedAverageGlucose,
    required this.category,
  });

  String get percentageFormatted => '${percentage.toStringAsFixed(1)}%';
  String get eagFormatted => '${estimatedAverageGlucose.round()} mg/dL';
}

enum HbA1cCategory {
  normal,
  prediabetes,
  diabetes,
}

extension HbA1cCategoryX on HbA1cCategory {
  String get label {
    switch (this) {
      case HbA1cCategory.normal:
        return 'Normal';
      case HbA1cCategory.prediabetes:
        return 'Prediabetes';
      case HbA1cCategory.diabetes:
        return 'Diabetes Range';
    }
  }

  String get labelAr {
    switch (this) {
      case HbA1cCategory.normal:
        return 'طبيعي';
      case HbA1cCategory.prediabetes:
        return 'ما قبل السكري';
      case HbA1cCategory.diabetes:
        return 'نطاق السكري';
    }
  }

  String get description {
    switch (this) {
      case HbA1cCategory.normal:
        return 'Your estimated HbA1c is in the normal range. Keep up the good work!';
      case HbA1cCategory.prediabetes:
        return 'Your estimated HbA1c indicates prediabetes. Consider consulting your healthcare provider.';
      case HbA1cCategory.diabetes:
        return 'Your estimated HbA1c is in the diabetes range. Please consult your healthcare provider for guidance.';
    }
  }

  String get descriptionAr {
    switch (this) {
      case HbA1cCategory.normal:
        return 'النسبة المقدرة لـ HbA1c في النطاق الطبيعي. واصل العمل الجيد!';
      case HbA1cCategory.prediabetes:
        return 'نسبة HbA1c المقدرة تشير إلى ما قبل السكري. فكر في استشارة طبيبك.';
      case HbA1cCategory.diabetes:
        return 'نسبة HbA1c المقدرة في نطاق السكري. يُرجى استشارة طبيبك للحصول على الإرشادات.';
    }
  }

  int get colorHex {
    switch (this) {
      case HbA1cCategory.normal:
        return 0xFF10B981; // green
      case HbA1cCategory.prediabetes:
        return 0xFFF59E0B; // amber
      case HbA1cCategory.diabetes:
        return 0xFFEF4444; // red
    }
  }
}

class HbA1cCalculator {
  /// Disclaimer to display alongside any estimated HbA1c value.
  ///
  /// Finger-stick averages are not a substitute for a lab HbA1c: sampling
  /// frequency, post-prandial peaks, and nocturnal hypoglycemia can all
  /// shift the estimate by up to +/-1.5 percentage points.
  static const String disclaimer =
      'This HbA1c estimate is based on finger-stick readings, not a continuous '
      'glucose monitor. It may differ from a lab HbA1c by up to ±1.5%. '
      'Consult your doctor for clinical decisions.';

  /// ADAG formula: eAG (mg/dL) = (28.7 × HbA1c%) − 46.7
  static double eagFromHbA1c(double hba1c) => (28.7 * hba1c) - 46.7;

  /// Inverse ADAG: HbA1c% = (eAG + 46.7) / 28.7.
  ///
  /// Returns `null` if [eag] is outside the physiologically plausible range
  /// (20–600 mg/dL). Such values almost always indicate a data-entry error
  /// or a corrupted reading and would otherwise produce nonsensical HbA1c
  /// numbers (e.g. < 3% or > 20%).
  static double? hba1cFromEag(double eag) {
    if (eag < 20 || eag > 600) return null;
    return (eag + 46.7) / 28.7;
  }

  /// Categorize HbA1c value
  static HbA1cCategory categorize(double hba1c) {
    if (hba1c < 5.7) return HbA1cCategory.normal;
    if (hba1c < 6.5) return HbA1cCategory.prediabetes;
    return HbA1cCategory.diabetes;
  }

  /// Calculate estimated HbA1c from a list of readings.
  /// Uses the average glucose from readings in the last 90 days.
  ///
  /// Non-physiological readings (value < 20 or > 600 mg/dL) are filtered
  /// out before averaging — they are almost always measurement or
  /// data-entry errors and would otherwise skew the eAG dramatically
  /// (a single 999 reading can shift a 90-day average by tens of mg/dL).
  static HbA1cResult? calculate(List<Reading> readings) {
    if (readings.isEmpty) return null;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 90));

    final recentReadings = readings
        .where((r) => r.timestamp.isAfter(cutoff))
        .where((r) => r.value >= 20 && r.value <= 600) // physiological bounds
        .toList();

    if (recentReadings.isEmpty) return null;

    final values = recentReadings.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;

    final hba1c = hba1cFromEag(avg);
    if (hba1c == null) return null;
    final category = categorize(hba1c);

    return HbA1cResult(
      percentage: hba1c,
      estimatedAverageGlucose: avg,
      category: category,
    );
  }

  /// Quick calculation from average glucose value.
  ///
  /// Returns `null` if [averageGlucose] is outside the physiological
  /// range (20–600 mg/dL).
  static HbA1cResult? fromAverage(double averageGlucose) {
    final hba1c = hba1cFromEag(averageGlucose);
    if (hba1c == null) return null;
    return HbA1cResult(
      percentage: hba1c,
      estimatedAverageGlucose: averageGlucose,
      category: categorize(hba1c),
    );
  }
}
