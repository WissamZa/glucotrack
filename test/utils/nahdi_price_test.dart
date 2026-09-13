// Tests for the Nahdi price parser — pure HTML parsing of the embedded
// search-result records (no network).
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/services/nahdi_price_service.dart';

const samplePage = '''
{"hits":[{"name":[[{"value":"بنادول","matchLevel":"none"}],[{"value":"اكسترا"}]],
"price":{"SAR":{"default":8,"default_formated":"8.00 ر س","special_from_date":""}},
"objectID":"117154"},
{"name":[[{"value":"أدول","matchLevel":"none"}]],
"price":{"SAR":{"default":6.05,"default_formated":"6.05 ر س"}},
"objectID":"1180"},
{"name":[[{"value":"بروفين","matchLevel":"none"}]],
"price":{"SAR":{"default":0,"default_formated":"0.00 ر س"}},
"objectID":"1190"}
]}
''';

void main() {
  group('NahdiPrice.parseFromHtml', () {
    test('extracts name + price pairs in order', () {
      final out = NahdiPrice.parseFromHtml(samplePage);
      expect(out.length, 2, reason: 'zero-price record must be skipped');
      expect(out.first.productName, 'بنادول');
      expect(out.first.priceSar, 8.0);
      expect(out.first.formatted, '8.00 ر س');
      expect(out.last.productName, 'أدول');
      expect(out.last.priceSar, 6.05);
    });

    test('caps at 3 results', () {
      final many = List.generate(
        6,
        (i) =>
            '{"name":[[{"value":"دواء $i"}]],"price":{"SAR":{"default":${i + 1}}}}',
      ).join(',');
      final out = NahdiPrice.parseFromHtml('{"hits":[$many]}');
      expect(out.length, 3);
    });

    test('returns empty for a page without prices', () {
      expect(NahdiPrice.parseFromHtml('<html>no data</html>'), isEmpty);
    });
  });
}
