// Nahdi Pharmacy lookup (nahdionline.com — largest Saudi chain).
//
// The site's search endpoint (with an `_rsc` marker, which makes the Next.js
// server stream its data payload) embeds rich product records: Arabic/English
// names, price in SAR, stock status, image URL, active ingredients and
// Arabic usage lines ("طريقة الاستخدام"). Parsing is tolerant to both the
// raw-stream shape and the HTML-embedded (Algolia-highlighted) shape.
//
// Prices/stock change — data is always shown as "approximate, best-effort"
// and lookups silently degrade to empty when offline or blocked.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NahdiProduct {
  final String sku;
  final String nameAr;
  final String? nameEn;
  final double? priceSar;
  final String? priceFormatted;
  final bool inStock;
  final String? imageUrl;
  final String? brandAr;
  final String? concentration;
  final List<String> usageLines;
  final List<String> ingredients;

  const NahdiProduct({
    required this.sku,
    required this.nameAr,
    this.nameEn,
    this.priceSar,
    this.priceFormatted,
    this.inStock = true,
    this.imageUrl,
    this.brandAr,
    this.concentration,
    this.usageLines = const [],
    this.ingredients = const [],
  });
}

class NahdiPriceService {
  static final NahdiPriceService _instance = NahdiPriceService._internal();
  factory NahdiPriceService() => _instance;
  NahdiPriceService._internal();

  static const _searchUrl = 'https://www.nahdionline.com/ar-sa/search';

  final Map<String, List<NahdiProduct>> _memoryCache = {};

  /// Best-effort product lookup. Returns an empty list when offline/blocked —
  /// callers simply hide the Nahdi section.
  Future<List<NahdiProduct>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final cacheKey = q.toLowerCase();
    final cached = _memoryCache[cacheKey];
    if (cached != null) return cached;

    try {
      final response = await http
          .get(
            Uri.parse('$_searchUrl?query=${Uri.encodeComponent(q)}&_rsc=1'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
              'Accept-Language': 'ar-SA,ar;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final products = parseProducts(body);
      _memoryCache[cacheKey] = products;
      return products;
    } on Exception catch (e) {
      debugPrint('Nahdi lookup unavailable: $e');
      return const [];
    }
  }

  /// Tolerant parser: walks every `"sku"` record in the payload and extracts
  /// whichever fields exist, handling both the raw-stream shape
  /// (`"sku":"123"` with plain arrays) and the HTML/Algolia shape
  /// (`"sku":{"value":"123"}` with highlight-wrapped values).
  static List<NahdiProduct> parseProducts(String payload) {
    String unescape(String input) {
      var out = input.replaceAll(r'\u0026', '&').replaceAll(r'\/', '/');
      out = out.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (m) {
        return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
      });
      return _stripHighlights(out.replaceAll(r'\"', '"')).trim();
    }

    final starts = _recordStarts(payload);
    final out = <NahdiProduct>[];
    for (var i = 0; i < starts.length; i++) {
      final segEnd = i + 1 < starts.length ? starts[i + 1] : payload.length;
      final seg = payload.substring(starts[i], segEnd);

      final sku = _scalar(seg, '"sku"');
      if (sku == null || sku.isEmpty) continue;

      String? nameAr;
      String? nameEn;
      for (final n in _allScalars(seg, '"name"')) {
        if (n.isEmpty) continue;
        final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(n);
        if (hasArabic && nameAr == null) nameAr = n;
        if (!hasArabic && nameEn == null) nameEn = n;
      }

      final priceMatch = RegExp(r'"price":\{"SAR":\{"default":([\d.]+)')
          .firstMatch(seg);
      final price = priceMatch != null
          ? double.tryParse(priceMatch.group(1)!)
          : null;
      final formatted =
          _scalar(seg, '"default_formated"') ?? '${price ?? ''} ر.س';

      final usage = _stringArray(
        seg,
        '"usage"',
        'arabic',
      ).take(4).map(unescape).toList();
      final ingredients = _stringArray(
        seg,
        '"ingredients"',
        null,
      ).take(4).toList();

      final imageRaw = _scalar(seg, '"image_url"');
      final inStockMatch = RegExp(r'"in_stock":(\d)').firstMatch(seg);
      final concentration = _scalar(seg, '"concentration"');
      final brandAr = _arrayFirst(seg, '"brand"');

      out.add(
        NahdiProduct(
          sku: sku,
          nameAr: unescape(nameAr ?? nameEn ?? sku),
          nameEn: nameEn != null ? unescape(nameEn) : null,
          priceSar: price,
          priceFormatted: price != null ? unescape(formatted) : null,
          inStock: inStockMatch == null || inStockMatch.group(1) == '1',
          imageUrl: imageRaw != null ? unescape(imageRaw) : null,
          brandAr: brandAr != null ? unescape(brandAr) : null,
          concentration: concentration != null ? unescape(concentration) : null,
          usageLines: usage,
          ingredients: ingredients,
        ),
      );
      if (out.length >= 5) break;
    }
    return out;
  }

  static String _stripHighlights(String input) => input
      .replaceAll('__ais-highlight__', '')
      .replaceAll('__/ais-highlight__', '');

  /// Record start offsets: both `"sku":"…"` and `"sku":{"value":"…"}`.
  static List<int> _recordStarts(String payload) {
    final starts = <int>[
      ...RegExp(r'"sku":"').allMatches(payload).map((m) => m.start),
      ...RegExp(r'"sku":\{"value"').allMatches(payload).map((m) => m.start),
    ]..sort();
    return starts;
  }

  /// First scalar after [key]: `"key":"value"` (or a bare number).
  static String? _scalar(String seg, String key) {
    final m = RegExp('${RegExp.escape(key)}"?:?"?([^",}{\\\\]+)')
        .firstMatch(seg);
    return m?.group(1);
  }

  /// All scalar values after repeated occurrences of [key].
  static List<String> _allScalars(String seg, String key) {
    return RegExp('${RegExp.escape(key)}"?:?"?([^",}{\\\\]+)')
        .allMatches(seg)
        .map((m) => m.group(1) ?? '')
        .toList();
  }

  /// First value inside a value-array like `"key":[["a","b"],…]`, tolerating
  /// both plain strings and {"value":"…"} objects.
  static String? _arrayFirst(String seg, String key) {
    final start = seg.indexOf('$key:');
    if (start < 0) return null;
    final m = RegExp(r'"value":"([^"]+)"|"([^"\[\]]+)"')
        .firstMatch(seg.substring(start));
    return m?.group(1) ?? m?.group(2);
  }

  /// Collects the [subKey] string array of an object field, or the whole
  /// string-array when [subKey] is null.
  static List<String> _stringArray(String seg, String key, String? subKey) {
    final start = seg.indexOf('$key:');
    if (start < 0) return const [];
    var window = seg.substring(start);
    if (subKey != null) {
      final sub = window.indexOf('"$subKey"');
      if (sub < 0) return const [];
      window = window.substring(sub);
    }
    final m = RegExp(r'\[(\[[^\]]*\]|[^\]]*)\]').firstMatch(window);
    if (m == null) return const [];
    final inner = m.group(1)!;
    if (inner.contains('"value"')) {
      return RegExp(r'"value":"([^"]+)"')
          .allMatches(inner)
          .map((x) => x.group(1) ?? '')
          .where((v) => v.isNotEmpty)
          .take(6)
          .toList();
    }
    return RegExp(r'"([^"]+)"')
        .allMatches(inner)
        .map((x) => x.group(1) ?? '')
        .where((v) => v.isNotEmpty)
        .take(6)
        .toList();
  }
}
