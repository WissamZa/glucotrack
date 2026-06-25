// Unit tests for the Settings model.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/settings.dart';

void main() {
  group('Settings model', () {
    const defaultSettings = Settings();

    // ── Defaults ────────────────────────────────────────────────────────────
    group('defaults', () {
      test('default language is Arabic', () {
        expect(defaultSettings.language, Language.ar);
      });

      test('default theme is classic', () {
        expect(defaultSettings.theme, ThemeStyle.classic);
      });

      test('default diabetes type is type2', () {
        expect(defaultSettings.diabetesType, DiabetesType.type2);
      });

      test('default targetMin is 80', () {
        expect(defaultSettings.targetMin, 80);
      });

      test('default targetMax is 180', () {
        expect(defaultSettings.targetMax, 180);
      });

      test('default unit is mg/dL', () {
        expect(defaultSettings.unit, GlucoseUnit.mgDl);
      });

      test('default userName is empty', () {
        expect(defaultSettings.userName, '');
      });

      test('default onboarded is false', () {
        expect(defaultSettings.onboarded, false);
      });
    });

    // ── isRtl ───────────────────────────────────────────────────────────────
    group('isRtl', () {
      test('Arabic is RTL', () {
        expect(defaultSettings.isRtl, true);
      });

      test('English is LTR', () {
        const s = Settings(language: Language.en);
        expect(s.isRtl, false);
      });
    });

    // ── LanguageX ────────────────────────────────────────────────────────────
    group('LanguageX', () {
      test('Arabic code is ar', () {
        expect(Language.ar.code, 'ar');
      });

      test('English code is en', () {
        expect(Language.en.code, 'en');
      });

      test('Arabic isRtl is true', () {
        expect(Language.ar.isRtl, true);
      });

      test('English isRtl is false', () {
        expect(Language.en.isRtl, false);
      });
    });

    // ── copyWith() ──────────────────────────────────────────────────────────
    group('copyWith()', () {
      test('returns same values when no overrides', () {
        final copy = defaultSettings.copyWith();
        expect(copy.language, defaultSettings.language);
        expect(copy.theme, defaultSettings.theme);
        expect(copy.diabetesType, defaultSettings.diabetesType);
        expect(copy.targetMin, defaultSettings.targetMin);
        expect(copy.targetMax, defaultSettings.targetMax);
        expect(copy.unit, defaultSettings.unit);
        expect(copy.userName, defaultSettings.userName);
        expect(copy.onboarded, defaultSettings.onboarded);
      });

      test('overrides only specified fields', () {
        final copy = defaultSettings.copyWith(
          language: Language.en,
          theme: ThemeStyle.modern,
          onboarded: true,
          userName: 'Ahmed',
        );
        expect(copy.language, Language.en);
        expect(copy.theme, ThemeStyle.modern);
        expect(copy.onboarded, true);
        expect(copy.userName, 'Ahmed');
        // Unmodified fields stay the same
        expect(copy.diabetesType, DiabetesType.type2);
        expect(copy.targetMin, 80);
        expect(copy.targetMax, 180);
        expect(copy.unit, GlucoseUnit.mgDl);
      });

      test('can update targetMin and targetMax independently', () {
        final copy = defaultSettings.copyWith(targetMin: 70, targetMax: 160);
        expect(copy.targetMin, 70);
        expect(copy.targetMax, 160);
        // Ensure other fields are preserved
        expect(copy.language, Language.ar);
      });
    });

    // ── SortOrder enum ────────────────────────────────────────────────────
    group('SortOrder enum', () {
      test('has all four expected values', () {
        expect(SortOrder.values.length, 4);
        expect(SortOrder.values, containsAll([
          SortOrder.newest,
          SortOrder.oldest,
          SortOrder.highest,
          SortOrder.lowest,
        ]),);
      });
    });

    // ── Enums completeness ─────────────────────────────────────────────────
    group('Enum completeness', () {
      test('ThemeStyle has 3 values', () {
        expect(ThemeStyle.values.length, 3);
      });

      test('DiabetesType has 3 values', () {
        expect(DiabetesType.values.length, 3);
      });

      test('GlucoseUnit has 2 values', () {
        expect(GlucoseUnit.values.length, 2);
      });

      test('Language has 2 values', () {
        expect(Language.values.length, 2);
      });
    });
  });
}
