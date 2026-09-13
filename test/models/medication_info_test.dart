// Tests for the RxNorm payload parsers (medication lookup) — pure JSON
// parsing, no network involved.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/models/medication_info.dart';

void main() {
  group('MedicationInfo.parseApproximateTerms', () {
    test('parses candidates, dedupes and caps at 8', () {
      final candidates = List.generate(
        12,
        (i) => {
          'rxcui': '100$i',
          'name': 'Drug $i',
          'synonym': 'Syn $i',
          'tty': 'IN',
          'score': '${100 - i}',
        },
      );
      final json = {
        'approximateGroup': {'queryTerm': 'drug', 'candidate': candidates},
      };

      final out = MedicationInfo.parseApproximateTerms(json, fetchedAt: 1000);
      expect(out.length, 8, reason: 'suggestions are capped at 8');
      expect(out.first.rxcui, '1000');
      expect(out.first.name, 'Drug 0');
      expect(out.first.tty, 'IN');
      expect(out.first.fetchedAt, 1000);
    });

    test('skips entries without rxcui or name', () {
      final json = {
        'approximateGroup': {
          'candidate': [
            {'name': 'No id'},
            {'rxcui': '42'},
            {'rxcui': '43', 'name': 'Valid'},
          ],
        },
      };
      final out = MedicationInfo.parseApproximateTerms(json, fetchedAt: 1);
      expect(out.length, 1);
      expect(out.single.rxcui, '43');
    });

    test('empty/missing structure yields an empty list', () {
      expect(MedicationInfo.parseApproximateTerms({}, fetchedAt: 1), isEmpty);
      expect(
        MedicationInfo.parseApproximateTerms({
          'approximateGroup': {},
        }, fetchedAt: 1),
        isEmpty,
      );
    });
  });

  group('MedicationInfo.parseAllProperties', () {
    test('maps props to fields, matching dose form and strength', () {
      final json = {
        'propConceptGroup': {
          'propConcept': [
            {'propName': 'name', 'propValue': 'ibuprofen'},
            {'propName': 'synonym', 'propValue': 'Advil'},
            {'propName': 'tty', 'propValue': 'SBD'},
            {'propName': 'Dose Form', 'propValue': 'Tablet'},
            {'propName': 'Strength', 'propValue': '200 mg/1'},
          ],
        },
      };

      final info = MedicationInfo.parseAllProperties(json, '5640')!;
      expect(info.name, 'ibuprofen');
      expect(info.synonym, 'Advil');
      expect(info.tty, 'SBD');
      expect(info.doseForm, 'Tablet');
      expect(info.strength, '200 mg/1');
      expect(info.isFresh, isTrue);
    });

    test('returns null when no properties exist', () {
      expect(MedicationInfo.parseAllProperties(const {}, '1'), isNull);
    });
  });

  group('MedicationInfo cache', () {
    test('DB round-trip keeps every field', () {
      const original = MedicationInfo(
        rxcui: '5640',
        name: 'ibuprofen',
        synonym: 'Advil',
        doseForm: 'Tablet',
        strength: '200 mg/1',
        tty: 'SBD',
        fetchedAt: 1700000000000,
      );
      final restored = MedicationInfo.fromDb(original.toDb());
      expect(restored.rxcui, '5640');
      expect(restored.name, 'ibuprofen');
      expect(restored.synonym, 'Advil');
      expect(restored.doseForm, 'Tablet');
      expect(restored.strength, '200 mg/1');
      expect(restored.tty, 'SBD');
      expect(restored.fetchedAt, 1700000000000);
    });

    test('freshness window is 30 days', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fresh = MedicationInfo(
        rxcui: '1',
        name: 'a',
        fetchedAt: now - const Duration(days: 5).inMilliseconds,
      );
      final stale = MedicationInfo(
        rxcui: '2',
        name: 'b',
        fetchedAt: now - const Duration(days: 45).inMilliseconds,
      );
      expect(fresh.isFresh, isTrue);
      expect(stale.isFresh, isFalse);
    });
  });
}
