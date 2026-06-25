// Glucose trend analysis — calculates direction and rate of change.
//
// Uses CGM-standard rates in mg/dL per MINUTE (not per hour).
// Thresholds follow common CGM conventions:
//   risingFast:   >= +3 mg/dL/min
//   rising:       +2 to +3 mg/dL/min
//   stable:       -2 to +2 mg/dL/min
//   falling:      -2 to -3 mg/dL/min
//   fallingFast:  <= -3 mg/dL/min
//
// Rates exceeding +/-10 mg/dL/min are treated as measurement artifacts
// and rejected (fromReadings returns null) — they are physiologically
// implausible for capillary glucose and almost always indicate a
// corrupted or mismatched reading.
import 'package:flutter/material.dart';
import '../models/reading.dart';

/// Glucose trend direction.
enum TrendDirection {
  risingFast, // >= +3 mg/dL/min
  rising, // +2 to +3 mg/dL/min
  stable, // -2 to +2 mg/dL/min
  falling, // -2 to -3 mg/dL/min
  fallingFast, // <= -3 mg/dL/min
}

extension TrendDirectionX on TrendDirection {
  String get label {
    switch (this) {
      case TrendDirection.risingFast:
        return 'Rising Fast';
      case TrendDirection.rising:
        return 'Rising';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.falling:
        return 'Falling';
      case TrendDirection.fallingFast:
        return 'Falling Fast';
    }
  }

  String get labelAr {
    switch (this) {
      case TrendDirection.risingFast:
        return 'ارتفاع سريع';
      case TrendDirection.rising:
        return 'في ارتفاع';
      case TrendDirection.stable:
        return 'مستقر';
      case TrendDirection.falling:
        return 'في انخفاض';
      case TrendDirection.fallingFast:
        return 'انخفاض سريع';
    }
  }

  String get arrow {
    switch (this) {
      case TrendDirection.risingFast:
        return '↑↑';
      case TrendDirection.rising:
        return '↑';
      case TrendDirection.stable:
        return '→';
      case TrendDirection.falling:
        return '↓';
      case TrendDirection.fallingFast:
        return '↓↓';
    }
  }
}

/// Result of a trend calculation.
class TrendResult {
  final TrendDirection direction;

  /// Rate of change in mg/dL per MINUTE (CGM standard).
  ///
  /// Note: previous versions of this field reported mg/dL per HOUR
  /// (`ratePerHour`); it was renamed to `ratePerMin` when the calculation
  /// switched to the CGM-standard per-minute convention.
  final double ratePerMin;

  const TrendResult({
    required this.direction,
    required this.ratePerMin,
  });
}

class TrendAnalyzer {
  // CGM-standard thresholds in mg/dL per MINUTE (not per hour).
  static const double _risingFastPerMin = 3.0;
  static const double _risingPerMin = 2.0;
  static const double _fallingPerMin = 2.0;
  static const double _fallingFastPerMin = 3.0;

  // Maximum plausible physiological rate. Anything beyond this is almost
  // certainly a measurement artifact (e.g. two readings from different
  // meters, a missed reading, or a corrupted sample).
  static const double _maxPhysiologicalRate = 10.0; // mg/dL/min

  /// Compute the trend from the two most recent readings.
  ///
  /// The list is assumed to be ordered most-recent-first (this matches the
  /// ordering maintained by [ReadingsProvider]). Returns `null` if:
  ///   - there are fewer than 2 readings,
  ///   - the two readings are less than 1 minute apart,
  ///   - the timestamps are not in chronological order, or
  ///   - the computed rate exceeds +/-10 mg/dL/min (non-physiological,
  ///     likely a measurement artifact).
  static TrendResult? fromReadings(List<Reading> readings) {
    if (readings.length < 2) return null;

    final current = readings.first;
    final previous = readings[1];

    final timeDiff = current.timestamp.difference(previous.timestamp);
    // Require at least 1 minute gap (was 5 minutes — too coarse for CGM).
    if (timeDiff.inSeconds < 60) return null;
    if (!current.timestamp.isAfter(previous.timestamp)) return null;

    final minutes = timeDiff.inSeconds / 60.0;
    final valueDiff = current.value - previous.value;
    final ratePerMin = valueDiff / minutes;

    // Filter out non-physiological rates (likely measurement error).
    if (ratePerMin.abs() > _maxPhysiologicalRate) return null;

    TrendDirection dir;
    if (ratePerMin >= _risingFastPerMin) {
      dir = TrendDirection.risingFast;
    } else if (ratePerMin >= _risingPerMin) {
      dir = TrendDirection.rising;
    } else if (ratePerMin <= -_fallingFastPerMin) {
      dir = TrendDirection.fallingFast;
    } else if (ratePerMin <= -_fallingPerMin) {
      dir = TrendDirection.falling;
    } else {
      dir = TrendDirection.stable;
    }

    return TrendResult(direction: dir, ratePerMin: ratePerMin);
  }

  /// Returns a color that reflects BOTH the trend direction AND the
  /// absolute glucose value relative to the user's target range.
  ///
  /// Semantics:
  ///   - Critical values (< 54 or > 250 mg/dL) are always RED regardless
  ///     of direction — the patient needs to act now.
  ///   - Rising while LOW   -> GREEN  (recovering toward range).
  ///   - Rising while HIGH  -> RED    (getting worse).
  ///   - Rising in range    -> AMBER  (about to leave the safe zone).
  ///   - Falling while HIGH -> GREEN  (improving toward range).
  ///   - Falling while LOW  -> RED    (getting worse).
  ///   - Falling in range   -> AMBER  (about to leave the safe zone).
  ///   - Stable in range    -> GREEN.
  ///   - Stable out of range -> AMBER.
  static Color colorFor(
    TrendDirection direction,
    int currentValue,
    int targetMin,
    int targetMax,
  ) {
    final inRange = currentValue >= targetMin && currentValue <= targetMax;
    final isLow = currentValue < targetMin;
    final isHigh = currentValue > targetMax;
    final isCritical = currentValue < 54 || currentValue > 250;

    // Critical values are always red regardless of direction.
    if (isCritical) return const Color(0xFFDC2626);

    switch (direction) {
      case TrendDirection.risingFast:
      case TrendDirection.rising:
        if (isLow) return const Color(0xFF16A34A); // green: recovering from low
        if (inRange) return const Color(0xFFF59E0B); // amber: rising out of range
        if (isHigh) return const Color(0xFFDC2626); // red: rising higher
        return const Color(0xFFF59E0B);
      case TrendDirection.stable:
        if (inRange) return const Color(0xFF16A34A); // green: stable in range
        return const Color(0xFFF59E0B); // amber: stable out of range
      case TrendDirection.falling:
      case TrendDirection.fallingFast:
        if (isHigh) return const Color(0xFF16A34A); // green: dropping toward range
        if (inRange) return const Color(0xFFF59E0B); // amber: dropping below range
        if (isLow) return const Color(0xFFDC2626); // red: dropping lower
        return const Color(0xFFF59E0B);
    }
  }

  /// Localized label for a trend direction.
  static String getLocalizedLabel(TrendDirection trend, bool isArabic) {
    return isArabic ? trend.labelAr : trend.label;
  }
}
