import 'package:flutter_test/flutter_test.dart';
import 'package:glucotrack/services/nahdi_price_service.dart';

void main() {
  test('NahdiPriceService implementation test', () async {
    // Test Panadol
    print('Searching Panadol...');
    final p1 = await NahdiPriceService().search('بانادول');
    print('Panadol count: ${p1.length}');
    expect(p1.isNotEmpty, isTrue);
    final topPanadol = p1.first;
    print('Panadol 1: ${topPanadol.nameAr}');
    print(' - Price: ${topPanadol.priceFormatted}');
    print(' - Stock: ${topPanadol.inStock}');
    print(' - Image: ${topPanadol.imageUrl}');
    print(' - Usage: ${topPanadol.usageLines}');
    print(' - Ingredients: ${topPanadol.ingredients}');
    print(' - Method: ${topPanadol.method}');
    print(' - Dosage: ${topPanadol.dosage}');
    print(' - Warnings: ${topPanadol.warnings}');

    // Test Glucophage
    print('\nSearching Glucophage...');
    final p2 = await NahdiPriceService().search('جلوكوفاج');
    print('Glucophage count: ${p2.length}');
    expect(p2.isNotEmpty, isTrue);
    final topGlucophage = p2.first;
    print('Glucophage 1: ${topGlucophage.nameAr}');
    print(' - Price: ${topGlucophage.priceFormatted}');
    print(' - Method: ${topGlucophage.method}');
    print(' - Dosage: ${topGlucophage.dosage}');
  });
}
