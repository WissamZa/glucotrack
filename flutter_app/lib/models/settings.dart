// App settings model — stored as a singleton row in DB.
enum Language { ar, en }

extension LanguageX on Language {
  /// ISO 639-1 code for use with intl's Locale
  String get code => this == Language.ar ? 'ar' : 'en';
  bool get isRtl => this == Language.ar;
}

enum ThemeStyle { classic, modern, elder }
enum DiabetesType { type1, type2, gestational }
enum GlucoseUnit { mgDl, mmolL }

class Settings {
  final Language language;
  final ThemeStyle theme;
  final DiabetesType diabetesType;
  final int targetMin; // mg/dL
  final int targetMax; // mg/dL
  final GlucoseUnit unit;
  final String userName;
  final bool onboarded;

  const Settings({
    this.language = Language.ar,
    this.theme = ThemeStyle.classic,
    this.diabetesType = DiabetesType.type2,
    this.targetMin = 80,
    this.targetMax = 180,
    this.unit = GlucoseUnit.mgDl,
    this.userName = '',
    this.onboarded = false,
  });

  bool get isRtl => language == Language.ar;

  Settings copyWith({
    Language? language,
    ThemeStyle? theme,
    DiabetesType? diabetesType,
    int? targetMin,
    int? targetMax,
    GlucoseUnit? unit,
    String? userName,
    bool? onboarded,
  }) =>
      Settings(
        language: language ?? this.language,
        theme: theme ?? this.theme,
        diabetesType: diabetesType ?? this.diabetesType,
        targetMin: targetMin ?? this.targetMin,
        targetMax: targetMax ?? this.targetMax,
        unit: unit ?? this.unit,
        userName: userName ?? this.userName,
        onboarded: onboarded ?? this.onboarded,
      );
}

enum SortOrder { newest, oldest, highest, lowest }
