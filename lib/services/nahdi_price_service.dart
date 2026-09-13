// Nahdi Pharmacy lookup (nahdionline.com — largest Saudi chain).
//
// The site server-renders enriched product records into its search page.
// This service fetches the page and extracts the COMPLETE record objects
// with a balanced-brace scanner (handles both raw-JSON and string-escaped
// stream chunks), then reads the known fields: Arabic/English names, price
// in SAR, stock, image, active ingredients and Arabic usage lines.
//
// Prices/stock change — data is shown as approximate/best-effort and the
// lookup silently degrades to empty when offline or blocked.
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

  /// Extracts complete record objects with a single string-aware forward
  /// pass: a stack of open-brace positions records each `"sku":` key's
  /// innermost enclosing object, which is then decoded. Handles raw JSON
  /// chunks; string-escaped chunks get an unescape fallback.
  static List<NahdiProduct> parseProducts(String payload) {
    final closeOf = <int, int>{};
    final skuEnclosing = <int>[];
    final stack = <int>[];
    var inStr = false;
    var esc = false;
    for (var i = 0; i < payload.length; i++) {
      final ch = payload[i];
      if (esc) {
        esc = false;
        continue;
      }
      if (inStr) {
        if (ch == r'\') {
          esc = true;
        } else if (ch == '"') {
          inStr = false;
        }
        continue;
      }
      if (ch == '"') {
        if (payload.startsWith('"sku":', i) && stack.isNotEmpty) {
          skuEnclosing.add(stack.last);
        }
        inStr = true;
      } else if (ch == '{') {
        stack.add(i);
      } else if (ch == '}') {
        if (stack.isNotEmpty) {
          closeOf[stack.removeLast()] = i;
        }
      }
    }

    final out = <NahdiProduct>[];
    final seen = <String>{};
    for (final open in skuEnclosing) {
      final close = closeOf[open];
      if (close == null) continue;
      final raw = payload.substring(open, close + 1);
      final product = _decodeRecord(raw);
      if (product == null) continue;
      if (!seen.add(product.sku)) continue;
      out.add(product);
      if (out.length >= 5) break;
    }
    return out;
  }

  /// Decodes a record object: raw JSON first, unescaped-string fallback.
  static NahdiProduct? _decodeRecord(String raw) {
    Map<String, dynamic>? rec;
    try {
      final decoded = jsonDecode(raw);
      rec = decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      try {
        final decoded = jsonDecode(
          raw.replaceAll(r'\"', '"').replaceAll(r'\\\\', r'\\'),
        );
        rec = decoded is Map<String, dynamic> ? decoded : null;
      } on FormatException {
        return null;
      }
    } on Exception {
      return null;
    }
    return rec == null ? null : _fromRecord(rec);
  }

  static String _fmtPrice(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Builds a [NahdiProduct] from a decoded record, tolerating both the raw
  /// shape (plain values) and the Algolia-highlighted shape ({value} objs).
  static NahdiProduct? _fromRecord(Map<String, dynamic> rec) {
    final sku = _str(rec['sku']);
    if (sku == null || sku.isEmpty) return null;

    final storeAr = _mapOf(rec['store_ar']);
    final storeEn = _mapOf(rec['store_en']);
    final nameAr =
        _str(storeAr?['name']) ??
        _str(_mapOf(storeAr?['name'])?['value']) ??
        _str(rec['name']);
    final nameEn =
        _str(storeEn?['name']) ?? _str(_mapOf(storeEn?['name'])?['value']);

    // Two price shapes: Algolia `price.SAR.default` and flight
    // `price.{currency,value}`.
    final priceMap = _mapOf(_mapOf(rec['price'])?['SAR']);
    var price = (priceMap?['default'] as num?)?.toDouble();
    var formatted = _str(priceMap?['default_formated']);
    if (price == null) {
      final flat = _mapOf(rec['price']);
      price = (flat?['value'] as num?)?.toDouble();
      formatted ??= price != null ? '${_fmtPrice(price)} ر.س' : null;
    }

    final usage = _stringList(_mapOf(rec['usage'])?['arabic']);
    var ingredients = _stringList(rec['active_ingredients']);
    if (ingredients.isEmpty) ingredients = _stringList(rec['ingredients']);
    if (ingredients.isEmpty) ingredients = _stringList(rec['ingredient']);
    if (ingredients.isEmpty) ingredients = _stringList(rec['transliteration']);
    final brand = _stringList(rec['brand']).firstOrNull;

    return NahdiProduct(
      sku: sku,
      nameAr: nameAr ?? nameEn ?? sku,
      nameEn: nameEn,
      priceSar: price,
      priceFormatted: formatted,
      inStock: rec['in_stock'] == null || rec['in_stock'] == 1,
      imageUrl: _str(rec['image_url']) ?? _str(rec['image']),
      brandAr: brand,
      concentration: _str(rec['concentration']),
      usageLines: usage,
      ingredients: ingredients,
    );
  }

  static Map<String, dynamic>? _mapOf(dynamic v) =>
      v is Map<String, dynamic> ? v : null;

  /// Flattens "value"-wrapped/highlighted strings; strips Algolia markers.
  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return _clean(v);
    if (v is Map) {
      final inner = v['value'];
      return inner == null ? null : _clean(inner.toString());
    }
    return null;
  }

  /// Flattens nested string arrays like [["a","b"],[{"value":"c"}]] / "str".
  static List<String> _stringList(dynamic v) {
    final out = <String>[];
    void addStr(String s) {
      final cleaned = _clean(s);
      if (cleaned.isNotEmpty) out.add(cleaned);
    }

    if (v is String) {
      addStr(v);
    } else if (v is List) {
      for (final item in v) {
        if (item is String) {
          addStr(item);
        } else if (item is List) {
          for (final inner in item) {
            if (inner is String) {
              addStr(inner);
            } else if (inner is Map && inner['value'] != null) {
              addStr(inner['value'].toString());
            }
          }
        } else if (item is Map && item['value'] != null) {
          addStr(item['value'].toString());
        }
      }
    } else if (v is Map && v['value'] != null) {
      addStr(v['value'].toString());
    }
    return out.take(4).toList();
  }

  static String _clean(String s) => s
      .replaceAll('__ais-highlight__', '')
      .replaceAll('__/ais-highlight__', '')
      .trim();
}
