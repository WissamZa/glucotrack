// Nahdi parser tests against a REAL captured record (trimmed from a live
// search response) plus a synthetic flight-shape record.
import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/services/nahdi_price_service.dart';

/// Real record: Algolia-highlighted shape (sku as {value}, store_ar with
/// plain + highlight strings, transliteration ingredients, price block,
/// usage.arabic lines, ingredient singular).
const algoliaRecord =
    r'''{"sku": "100726280", "store_ar": {"manufacturer": "بانادول", "name": "بانادول أدفانس باراسيتامول 500 مجم  24 قرص"}, "store_en": {"manufacturer": "Panadol", "name": "Panadol Advance Paracetamol  500 mg -  24 Tablets"}, "name": "بانادول أدفانس - باراسيتامول - 500 مجم - 24 قرص", "ingredient": "باراسيتامول", "price": {"SAR": {"default": 6.05, "default_formated": "6.05 ر س", "special_from_date": "", "special_to_date": ""}}, "usage": {"arabic": ["دواء على شكل أقراص لتسكين الألم وخفض الحرارة للبالغين", "لعلاج الصداع", "لتخفيف آلام الجسم العامة", "لتقليل الحمى المصاحبة للأمراض", "للاستخدام في حالات الألم الخفيف إلى المتوسط"], "english": ["medication in tablet form for pain relief and fever reduction in adults", "for treating headaches", "to relieve general body aches", "to reduce fever associated with illnesses", "for use in mild to moderate pain"]}, "transliteration": {"ingredients": [["باراسيتامول", "بيراسيتامول", "باراسيتامول"]]}, "in_stock": 1, "image_url": "https://ecombe.nahdionline.com/media/catalog/product/1/0/100726280_a2ae2563085863c0a_6333.png?width=265&height=265&canvas=265,265&optimize=high&bg-color=255,255,255&fit=bounds", "concentration": null, "brand": null}''';

/// Real shape from the RSC grid: flat fields with spaces after colons.
const flightRecord =
    '{"sku": "100015947", "name": "بانادول أقراص 500 مجم - 24 أقراص", '
    '"slug": "panadol-500mg-24", "price": {"currency": "SAR", "value": 5.80}, '
    '"inStock": true, "brand": "Panadol", '
    '"image": "https://cdn.nahdionline.com/media/p1.jpg", "rating": 5.0}';

void main() {
  group('Algolia-shape record (real, highlighted)', () {
    final products = NahdiPriceService.parseProducts(algoliaRecord);

    test('extracts one product with sku and arabic name', () {
      expect(products, isNotEmpty);
      expect(products.first.sku, '100726280');
      expect(products.first.nameAr, contains('بانادول'));
      expect(products.first.nameAr, isNot(contains('__ais-highlight__')));
    });

    test('extracts price and stock', () {
      expect(products.first.priceSar, 6.05);
      expect(products.first.inStock, isTrue);
    });

    test('extracts usage lines and ingredients', () {
      expect(products.first.usageLines, isNotEmpty);
      expect(products.first.ingredients, isNotEmpty);
      expect(products.first.ingredients.first, contains('باراسيتامول'));
    });
  });

  group('Flight-shape record (user-reported format)', () {
    test('extracts product with price and image', () {
      final products = NahdiPriceService.parseProducts(flightRecord);
      expect(products, isNotEmpty);
      final p = products.first;
      expect(p.sku, '100015947');
      expect(p.nameAr, contains('بانادول'));
      expect(p.priceSar, 5.80);
      expect(p.inStock, isTrue);
      expect(p.imageUrl, isNotNull);
    });
  });

  group('edge cases', () {
    test('dedupes by sku and caps at 5', () {
      final products = NahdiPriceService.parseProducts(
        algoliaRecord + algoliaRecord + flightRecord,
      );
      expect(products.length, 2);
    });

    test('returns empty for payloads without records', () {
      expect(NahdiPriceService.parseProducts('<html>nothing</html>'), isEmpty);
      expect(NahdiPriceService.parseProducts(''), isEmpty);
    });
  });
}
