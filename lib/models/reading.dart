// Reading model — represents a single blood glucose measurement.

/// Sentinel object used by [Reading.copyWith] (and other models) to
/// distinguish "argument not supplied" from "argument explicitly null".
///
/// Without this, callers have no way to clear a nullable field via copyWith
/// because `null` is treated the same as "keep the existing value".
class _Unset {
  const _Unset();
}

const _unset = _Unset();

enum ReadingType {
  fasting,
  beforeMeal,
  afterMeal,
  beforeSleep,
  afterExercise,
  other,
}

const Map<String, ReadingType> _readingTypeFromString = {
  'fasting': ReadingType.fasting,
  'before_meal': ReadingType.beforeMeal,
  'after_meal': ReadingType.afterMeal,
  'before_sleep': ReadingType.beforeSleep,
  'after_exercise': ReadingType.afterExercise,
  'other': ReadingType.other,
};

const Map<ReadingType, String> _readingTypeToString = {
  ReadingType.fasting: 'fasting',
  ReadingType.beforeMeal: 'before_meal',
  ReadingType.afterMeal: 'after_meal',
  ReadingType.beforeSleep: 'before_sleep',
  ReadingType.afterExercise: 'after_exercise',
  ReadingType.other: 'other',
};

extension ReadingTypeX on ReadingType {
  String get dbValue => _readingTypeToString[this]!;
  static ReadingType fromDb(String s) => _readingTypeFromString[s] ?? ReadingType.other;
}

enum ReadingStatus {
  criticalLow,   // <54 (Level 2 hypo - requires immediate action)
  warningLow,    // 54-69 (Level 1 hypo - should take action)
  low,           // 70 to targetMin
  inRange,       // targetMin to targetMax
  high,          // targetMax to 250
  criticalHigh,  // >250
}

class Reading {
  final String id;
  final int value;
  final ReadingType type;
  final DateTime timestamp;
  final String? notes;
  final int? carbs;
  final int? insulin;

  const Reading({
    required this.id,
    required this.value,
    required this.type,
    required this.timestamp,
    this.notes,
    this.carbs,
    this.insulin,
  });

  ReadingStatus status(int targetMin, int targetMax) {
    if (value < 54) return ReadingStatus.criticalLow;
    if (value < 70) return ReadingStatus.warningLow;
    if (value < targetMin) return ReadingStatus.low;
    if (value <= targetMax) return ReadingStatus.inRange;
    if (value <= 250) return ReadingStatus.high;
    return ReadingStatus.criticalHigh;
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'value': value,
        'type': type.dbValue,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'notes': notes,
        'carbs': carbs,
        'insulin': insulin,
      };

  factory Reading.fromDb(Map<String, dynamic> m) => Reading(
        id: m['id'] as String,
        value: m['value'] as int,
        type: ReadingTypeX.fromDb(m['type'] as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
        notes: m['notes'] as String?,
        carbs: m['carbs'] as int?,
        insulin: m['insulin'] as int?,
      );

  Reading copyWith({
    Object? id = _unset,
    Object? value = _unset,
    Object? type = _unset,
    Object? timestamp = _unset,
    Object? notes = _unset,
    Object? carbs = _unset,
    Object? insulin = _unset,
  }) =>
      Reading(
        id: identical(id, _unset) ? this.id : id as String,
        value: identical(value, _unset) ? this.value : value as int,
        type: identical(type, _unset) ? this.type : type as ReadingType,
        timestamp: identical(timestamp, _unset)
            ? this.timestamp
            : timestamp as DateTime,
        notes: identical(notes, _unset) ? this.notes : notes as String?,
        carbs: identical(carbs, _unset) ? this.carbs : carbs as int?,
        insulin: identical(insulin, _unset) ? this.insulin : insulin as int?,
      );
}
