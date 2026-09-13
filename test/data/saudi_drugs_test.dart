// Tests for the bundled Saudi drug library — Arabic-normalized search is
// the core of the default (offline) medication source.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/data/saudi_drugs.dart';
import 'package:glucotrack/models/medication_info.dart';

void main() {
  group('searchSaudiDrugs', () {
    test('matches English names case-insensitively', () {
      final out = searchSaudiDrugs('panadol');
      expect(out, isNotEmpty);
      expect(out.first.nameEn, 'Panadol');
      expect(searchSaudiDrugs('PANADOL'), isNotEmpty);
    });

    test('matches Arabic names', () {
      final out = searchSaudiDrugs('بنادول');
      expect(out, isNotEmpty);
      expect(out.first.nameEn, 'Panadol');
    });

    test('Arabic normalization: harakat and alef forms match', () {
      // Harakat are stripped: 'بَنَادُول' → 'بنادول'.
      expect(searchSaudiDrugs('بَنَادُول'), isNotEmpty);
      // أ/إ/آ are unified with ا: plain alef hits 'أوجمنتين'.
      expect(searchSaudiDrugs('اوجمنتين'), isNotEmpty);
      // Substring matches still work ('بروفين' hits 'بروفينال').
      expect(searchSaudiDrugs('بروفين'), isNotEmpty);
    });

    test('matches active ingredient names', () {
      final out = searchSaudiDrugs('metformin');
      expect(out, isNotEmpty);
      expect(out.first.ingredient.toLowerCase(), contains('metformin'));
    });

    test('returns empty for short/garbage queries', () {
      expect(searchSaudiDrugs(''), isEmpty);
      expect(searchSaudiDrugs('zzzzzz'), isEmpty);
    });

    test('library covers the essential categories (sanity size)', () {
      expect(kSaudiDrugs.length, greaterThanOrEqualTo(60));
      final ids = kSaudiDrugs.map((d) => d.id).toSet();
      expect(ids.length, kSaudiDrugs.length, reason: 'ids must be unique');
    });

    test('every entry has both languages, form and strength', () {
      for (final d in kSaudiDrugs) {
        expect(d.nameEn.trim(), isNotEmpty, reason: d.id);
        expect(d.nameAr.trim(), isNotEmpty, reason: d.id);
        expect(d.formKey.trim(), isNotEmpty, reason: d.id);
        expect(d.strength.trim(), isNotEmpty, reason: d.id);
        expect(d.ingredient.trim(), isNotEmpty, reason: d.id);
        expect(d.usage.trim(), isNotEmpty, reason: d.id);
      }
    });

    test('prescription-only antibiotics are flagged otc=false', () {
      final augmentin = kSaudiDrugs.firstWhere((d) => d.id == 'augmentin');
      expect(augmentin.otc, isFalse);
      final panadol = kSaudiDrugs.firstWhere((d) => d.id == 'panadol');
      expect(panadol.otc, isTrue);
    });
  });

  group('SaudiDrug → MedicationInfo', () {
    test('builds a namespaced info with the saudi source', () {
      final info = kSaudiDrugs.first.toInfo();
      expect(info.source, 'saudi');
      expect(info.rxcui, startsWith('saudi:'));
      expect(MedicationInfo.sourceOf(info.rxcui), 'saudi');
      expect(info.name, kSaudiDrugs.first.nameEn);
      expect(info.synonym, kSaudiDrugs.first.nameAr);
      expect(info.isFresh, isTrue);
    });
  });
}
