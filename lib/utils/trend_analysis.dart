// Glucose trend analysis — calculates direction and rate of change
import '../models/reading.dart';

enum TrendDirection {
  risingFast,   // > 3 mg/dL per hour
  rising,       // 1-3 mg/dL per hour
  stable,       // -1 to 1 mg/dL per hour
  falling,      // -3 to -1 mg/dL per hour
  fallingFast,  // < -3 mg/dL per hour
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

  /// Color for trend indicator
  /// Note: rising can be good (low value rising to normal) or bad (normal rising to high)
  /// We use a neutral-semantic approach based on typical usage
  int get colorHex {
    switch (this) {
      case TrendDirection.risingFast:
        return 0xFFF59E0B; // amber - attention
      case TrendDirection.rising:
        return 0xFF10B981; // green - generally positive (recovering from low)
      case TrendDirection.stable:
        return 0xFF6B7280; // gray
      case TrendDirection.falling:
        return 0xFFF59E0B; // amber - watch out
      case TrendDirection.fallingFast:
        return 0xFFEF4444; // red - danger
    }
  }
}

class TrendResult {
  final TrendDirection direction;
  final double ratePerHour; // mg/dL per hour
  final Duration timeSpan;

  const TrendResult({
    required this.direction,
    required this.ratePerHour,
    required this.timeSpan,
  });
}

class TrendAnalyzer {
  /// Calculate trend between two readings
  static TrendResult? calculateTrend(Reading? previous, Reading? current) {
    if (previous == null || current == null) return null;

    final timeDiff = current.timestamp.difference(previous.timestamp);
    if (timeDiff.inMinutes < 5) return null; // Need at least 5 minutes apart

    final valueDiff = current.value - previous.value;
    final hours = timeDiff.inMinutes / 60.0;
    if (hours <= 0) return null;

    final rate = valueDiff / hours;

    TrendDirection direction;
    if (rate > 3) {
      direction = TrendDirection.risingFast;
    } else if (rate > 1) {
      direction = TrendDirection.rising;
    } else if (rate >= -1) {
      direction = TrendDirection.stable;
    } else if (rate >= -3) {
      direction = TrendDirection.falling;
    } else {
      direction = TrendDirection.fallingFast;
    }

    return TrendResult(
      direction: direction,
      ratePerHour: rate,
      timeSpan: timeDiff,
    );
  }

  /// Find the trend using the two most recent readings
  static TrendResult? fromReadings(List<Reading> readings) {
    if (readings.length < 2) return null;
    final sorted = List<Reading>.from(readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return calculateTrend(sorted[1], sorted[0]);
  }

  /// Get a trend label localized
  static String getLocalizedLabel(TrendDirection trend, bool isArabic) {
    return isArabic ? trend.labelAr : trend.label;
  }
}
