// Reading model — represents a single blood glucose measurement.
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

enum ReadingStatus { low, inRange, high, criticalLow, criticalHigh }

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
    String? id,
    int? value,
    ReadingType? type,
    DateTime? timestamp,
    String? notes,
    int? carbs,
    int? insulin,
  }) =>
      Reading(
        id: id ?? this.id,
        value: value ?? this.value,
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        notes: notes ?? this.notes,
        carbs: carbs ?? this.carbs,
        insulin: insulin ?? this.insulin,
      );
}
