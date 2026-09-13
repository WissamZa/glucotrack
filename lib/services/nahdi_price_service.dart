// Nahdi Pharmacy price lookup (nahdionline.com — largest Saudi chain).
//
// The site embeds its search results (Algolia-style hits with
// price.SAR.default) in the HTML of /ar-sa/search?query=…, so we fetch the
// page and parse the embedded records. Prices are approximate and change —
// always shown with a disclaimer. Parsing is a pure static function so it
// is unit-testable against a captured page.
import 'package:http/http.dart' as http;

class NahdiPrice {
  final String productName;
  final double priceSar;
  final String formatted;

  const NahdiPrice({
    required this.productName,
    required this.priceSar,
    required this.formatted,
  });

  /// Extracts product prices from a Nahdi search page. Records look like:
  /// `"name":[[{"value":"بنادول",...}]] … "price":{"SAR":{"default":8,
  /// "default_formated":"8.00 ر س"`.
  static List<NahdiPrice> parseFromHtml(String html) {
    final namePattern = RegExp(r'"name":\[\[\{"value":"([^"]+)"');
    final pricePattern = RegExp(r'"price":\{"SAR":\{"default":([\d.]+)');
    final formattedPattern = RegExp(r'"default_formated":"([^"]+)"');

    final out = <NahdiPrice>[];
    final names = namePattern.allMatches(html).toList();
    final prices = pricePattern.allMatches(html).toList();
    final formattedList = formattedPattern.allMatches(html).toList();

    // Records stream in order: name … price … formatted. Walk them together.
    for (var i = 0; i < prices.length; i++) {
      final priceStr = prices[i].group(1);
      if (priceStr == null) continue;
      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) continue;

      // The product name is the last name-match before this price match.
      String? name;
      for (final n in names) {
        if (n.start > prices[i].start) break;
        name = n.group(1);
      }
      final formatted = i < formattedList.length
          ? formattedList[i].group(1)
          : null;

      if (name != null && name.isNotEmpty) {
        out.add(
          NahdiPrice(
            productName: name,
            priceSar: price,
            formatted: (formatted != null && formatted.isNotEmpty)
                ? formatted
                : '$price ر.س',
          ),
        );
      }
      if (out.length >= 3) break;
    }
    return out;
  }
}

class NahdiPriceService {
  static final NahdiPriceService _instance = NahdiPriceService._internal();
  factory NahdiPriceService() => _instance;
  NahdiPriceService._internal();

  static const _searchUrl = 'https://www.nahdionline.com/ar-sa/search';

  final Map<String, List<NahdiPrice>> _memoryCache = {};

  /// Best-effort price lookup. Returns an empty list when offline/blocked —
  /// callers simply hide the price section.
  Future<List<NahdiPrice>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final cached = _memoryCache[q.toLowerCase()];
    if (cached != null) return cached;

    try {
      final response = await http
          .get(
            Uri.parse('$_searchUrl?query=${Uri.encodeComponent(q)}'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
              'Accept-Language': 'ar-SA,ar;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final prices = NahdiPrice.parseFromHtml(response.body);
      _memoryCache[q.toLowerCase()] = prices;
      return prices;
    } on Exception {
      return const [];
    }
  }
}
