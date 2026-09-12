// Tests for the bundled health-tips content — integrity of the bilingual
// dataset and the deterministic tip-of-the-day selection.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/data/health_tips.dart';
import 'package:glucotrack/models/settings.dart';

void main() {
  group('health tips dataset integrity', () {
    test('dataset is non-trivial (>= 40 tips across 9 categories)', () {
      expect(kHealthTips.length, greaterThanOrEqualTo(40));
      final categories = kHealthTips.map((t) => t.category).toSet();
      expect(
        categories.length,
        TipCategoryId.values.length,
        reason: 'Every category must have at least one tip',
      );
      expect(TipCategoryId.values.length, 9);
    });

    test('every tip has non-empty titles and bodies in BOTH languages', () {
      for (final tip in kHealthTips) {
        expect(
          tip.titleAr.trim(),
          isNotEmpty,
          reason: '${tip.id}: empty Arabic title',
        );
        expect(
          tip.titleEn.trim(),
          isNotEmpty,
          reason: '${tip.id}: empty English title',
        );
        expect(
          tip.bodyAr.trim(),
          isNotEmpty,
          reason: '${tip.id}: empty Arabic body',
        );
        expect(
          tip.bodyEn.trim(),
          isNotEmpty,
          reason: '${tip.id}: empty English body',
        );
      }
    });

    test('tip ids are unique', () {
      final ids = kHealthTips.map((t) => t.id).toList();
      expect(ids.length, ids.toSet().length);
    });

    test('every tip category is registered in kTipCategories', () {
      final registered = kTipCategories.map((c) => c.id).toSet();
      for (final tip in kHealthTips) {
        expect(
          registered.contains(tip.category),
          isTrue,
          reason: '${tip.id}: category ${tip.category} has no metadata',
        );
      }
    });

    test('category metadata has labels in both languages', () {
      for (final cat in kTipCategories) {
        expect(cat.labelAr.trim(), isNotEmpty);
        expect(cat.labelEn.trim(), isNotEmpty);
      }
    });

    test('Arabic content actually contains Arabic script', () {
      // Guards against copy-paste mistakes that leave English in the AR field.
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      for (final tip in kHealthTips) {
        expect(
          arabicRegex.hasMatch(tip.titleAr),
          isTrue,
          reason: '${tip.id}: Arabic title has no Arabic characters',
        );
        expect(
          arabicRegex.hasMatch(tip.bodyAr),
          isTrue,
          reason: '${tip.id}: Arabic body has no Arabic characters',
        );
      }
    });

    test('language-aware accessors pick the right language', () {
      final tip = kHealthTips.first;
      expect(tip.title(Language.ar), tip.titleAr);
      expect(tip.title(Language.en), tip.titleEn);
      expect(tip.body(Language.ar), tip.bodyAr);
      expect(tip.body(Language.en), tip.bodyEn);
    });
  });

  group('tipOfTheDay', () {
    test('is stable within the same calendar day', () {
      final morning = DateTime(2026, 9, 12, 7, 0);
      final night = DateTime(2026, 9, 12, 23, 30);
      expect(tipOfTheDay(morning).id, tipOfTheDay(night).id);
    });

    test('is deterministic — same day always yields the same tip', () {
      final a = tipOfTheDay(DateTime(2026, 3, 1));
      final b = tipOfTheDay(DateTime(2026, 3, 1));
      expect(a.id, b.id);
    });

    test('cycles within the dataset (never throws, always valid)', () {
      for (var day = 0; day < 400; day++) {
        final tip = tipOfTheDay(DateTime(2026, 1, 1).add(Duration(days: day)));
        expect(kHealthTips.contains(tip), isTrue);
      }
    });
  });
}
