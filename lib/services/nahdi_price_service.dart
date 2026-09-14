// Nahdi Pharmacy lookup (nahdionline.com — largest Saudi chain).
//
// Search: requests the RSC data-stream endpoint to get product records
// (sku, name, slug, price, inStock, brand, image, rating).
//
// Details: for each product we fetch the individual product page using the
// slug and extract dosage / method-of-use / ingredients from the RSC stream
// embedded in the product page.
//
// Everything degrades silently when offline or blocked.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NahdiProduct {
  final String sku;
  final String nameAr;
  final String? nameEn;
  final String? slug;
  final double? priceSar;
  final String? priceFormatted;
  final bool inStock;
  final String? imageUrl;
  final String? brandAr;
  final String? concentration;
  final double? rating;
  final List<String> usageLines;
  final List<String> ingredients;
  final String? dosage;
  final String? method;

  const NahdiProduct({
    required this.sku,
    required this.nameAr,
    this.nameEn,
    this.slug,
    this.priceSar,
    this.priceFormatted,
    this.inStock = true,
    this.imageUrl,
    this.brandAr,
    this.concentration,
    this.rating,
    this.usageLines = const [],
    this.ingredients = const [],
    this.dosage,
    this.method,
  });

  NahdiProduct copyWithDetails({
    List<String>? usageLines,
    List<String>? ingredients,
    String? dosage,
    String? method,
  }) => NahdiProduct(
    sku: sku,
    nameAr: nameAr,
    nameEn: nameEn,
    slug: slug,
    priceSar: priceSar,
    priceFormatted: priceFormatted,
    inStock: inStock,
    imageUrl: imageUrl,
    brandAr: brandAr,
    concentration: concentration,
    rating: rating,
    usageLines: usageLines ?? this.usageLines,
    ingredients: ingredients ?? this.ingredients,
    dosage: dosage ?? this.dosage,
    method: method ?? this.method,
  );
}

class NahdiPriceService {
  static final NahdiPriceService _instance = NahdiPriceService._internal();
  factory NahdiPriceService() => _instance;
  NahdiPriceService._internal();

  static const _baseUrl = 'https://www.nahdionline.com';
  static const _searchPath = '/ar-sa/search';

  final Map<String, List<NahdiProduct>> _memoryCache = {};

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
    'Accept-Language': 'ar-SA,ar;q=0.9,en;q=0.8',
    'Next-Router-State-Tree': '%5B%22%22%2C%7B%7D%5D',
    'RSC': '1',
  };

  /// Best-effort product lookup. Returns an empty list when offline/blocked.
  /// Also enriches each result with per-product details (dosage, method, etc.)
  /// from the product detail page.
  Future<List<NahdiProduct>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final cacheKey = q.toLowerCase();
    final cached = _memoryCache[cacheKey];
    if (cached != null) return cached;

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl$_searchPath?query=${Uri.encodeComponent(q)}&_rsc=1',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final products = parseProducts(body);
      if (products.isEmpty) return const [];

      // Enrich top-3 products with detail page data (best effort, parallel).
      final enriched = await _enrichProducts(products.take(5).toList());
      _memoryCache[cacheKey] = enriched;
      return enriched;
    } on Exception catch (e) {
      debugPrint('Nahdi lookup unavailable: $e');
      return const [];
    }
  }

  /// Fetch per-product detail pages in parallel (fire-and-forget friendly).
  Future<List<NahdiProduct>> _enrichProducts(
    List<NahdiProduct> products,
  ) async {
    final results = await Future.wait(
      products.map((p) => _fetchProductDetails(p)),
    );
    return results;
  }

  /// Fetch the individual product page and extract detail fields.
  Future<NahdiProduct> _fetchProductDetails(NahdiProduct product) async {
    final slug = product.slug;
    if (slug == null || slug.isEmpty) return product;
    try {
      final url = '$_baseUrl/ar-sa/$slug';
      final response = await http
          .get(Uri.parse('$url?_rsc=1'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return product;
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _extractProductDetails(product, body);
    } on Exception catch (e) {
      debugPrint('Nahdi product detail unavailable for ${product.slug}: $e');
      return product;
    }
  }

  /// Parse the RSC payload for a product detail page and extract
  /// usage, method, dosage and ingredients.
  static NahdiProduct _extractProductDetails(
    NahdiProduct product,
    String payload,
  ) {
    // Look for JSON objects that contain product detail fields.
    // The detail page RSC stream embeds objects with fields like:
    // "how_to_use", "dosage", "description", "active_ingredients", etc.
    final detailFields = _extractDetailFields(payload);
    if (detailFields == null) return product;

    final usageLines = <String>[];
    final ingredients = <String>[];

    // دواعي الاستخدام / indications
    final usageRaw =
        detailFields['how_to_use'] ??
        detailFields['usage'] ??
        detailFields['indications'] ??
        detailFields['indication'] ??
        detailFields['description'];
    if (usageRaw is String && usageRaw.trim().isNotEmpty) {
      // Split on newlines or Arabic-style list markers
      final lines = usageRaw
          .split(RegExp(r'[\n\r•·،,]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .take(4)
          .toList();
      usageLines.addAll(lines);
    }

    // المكونات
    final ingRaw =
        detailFields['active_ingredients'] ??
        detailFields['ingredients'] ??
        detailFields['ingredient'] ??
        detailFields['active_ingredient'];
    if (ingRaw is String && ingRaw.trim().isNotEmpty) {
      ingredients.add(ingRaw.trim());
    } else if (ingRaw is List) {
      for (final item in ingRaw) {
        if (item is String && item.trim().isNotEmpty) {
          ingredients.add(item.trim());
        }
      }
    }

    // الجرعة الموصى بها
    String? dosage;
    final dosageRaw =
        detailFields['dosage'] ??
        detailFields['dose'] ??
        detailFields['dosage_and_administration'];
    if (dosageRaw is String && dosageRaw.trim().isNotEmpty) {
      dosage = dosageRaw.trim();
    }

    // طريقة الاستخدام
    String? method;
    final methodRaw =
        detailFields['method_of_use'] ??
        detailFields['method'] ??
        detailFields['administration'];
    if (methodRaw is String && methodRaw.trim().isNotEmpty) {
      method = methodRaw.trim();
    }

    if (usageLines.isEmpty &&
        ingredients.isEmpty &&
        dosage == null &&
        method == null) {
      return product;
    }

    return product.copyWithDetails(
      usageLines: usageLines.isNotEmpty ? usageLines : null,
      ingredients: ingredients.isNotEmpty ? ingredients : null,
      dosage: dosage,
      method: method,
    );
  }

  /// Scans the payload for any JSON object containing product-detail keys
  /// and returns the first matching decoded map.
  static Map<String, dynamic>? _extractDetailFields(String payload) {
    // Keys that indicate a product detail object
    const detailKeys = {
      'how_to_use',
      'dosage',
      'active_ingredients',
      'ingredients',
      'method_of_use',
      'indications',
    };

    final stack = <int>[];
    var inStr = false;
    var esc = false;
    final objectStarts = <int>[];

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
        // Check for any detail key at this position
        for (final key in detailKeys) {
          if (payload.startsWith('"$key":', i) && stack.isNotEmpty) {
            objectStarts.add(stack.last);
            break;
          }
        }
        inStr = true;
      } else if (ch == '{') {
        stack.add(i);
      } else if (ch == '}') {
        if (stack.isNotEmpty) {
          final open = stack.removeLast();
          if (objectStarts.contains(open)) {
            objectStarts.remove(open);
            final raw = payload.substring(open, i + 1);
            final decoded = _tryDecode(raw);
            if (decoded != null) return decoded;
          }
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? _tryDecode(String raw) {
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? v : null;
    } on FormatException {
      try {
        final v = jsonDecode(
          raw.replaceAll(r'\"', '"').replaceAll(r'\\\\', r'\\'),
        );
        return v is Map<String, dynamic> ? v : null;
      } on FormatException {
        return null;
      }
    }
  }

  // ── Search result parsing ──────────────────────────────────────────────────

  /// Parses the RSC search payload.
  ///
  /// The Nahdi search RSC stream embeds product objects with these fields:
  ///   sku, name, slug, price.{currency,value}, inStock, brand, image, rating
  ///
  /// We use a balanced-brace scanner to find all objects that contain "sku"
  /// (the stable field present in every product record) and decode them.
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

  static NahdiProduct? _decodeRecord(String raw) {
    final rec = _tryDecode(raw);
    if (rec == null) return null;
    return _fromRecord(rec);
  }

  static String _fmtPrice(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Builds a [NahdiProduct] from a decoded record.
  /// Handles both the simple RSC shape {sku, name, slug, price.{currency,value},
  /// inStock, brand, image, rating} and the legacy Algolia shape with store_ar/SAR.
  static NahdiProduct? _fromRecord(Map<String, dynamic> rec) {
    final sku = _str(rec['sku']);
    if (sku == null || sku.isEmpty) return null;

    // Name: prefer Arabic store name, fall back to plain name field
    final storeAr = _mapOf(rec['store_ar']);
    final storeEn = _mapOf(rec['store_en']);
    final nameAr =
        _str(storeAr?['name']) ??
        _str(_mapOf(storeAr?['name'])?['value']) ??
        _str(rec['name']);
    final nameEn =
        _str(storeEn?['name']) ?? _str(_mapOf(storeEn?['name'])?['value']);

    // Price: RSC simple shape → price.{currency,value}; Algolia → price.SAR.default
    double? price;
    String? formatted;

    final priceObj = _mapOf(rec['price']);
    if (priceObj != null) {
      // Simple RSC shape
      final val = priceObj['value'];
      price = (val is num) ? val.toDouble() : null;
      final currency = _str(priceObj['currency']) ?? 'SAR';
      if (price != null) formatted = '${_fmtPrice(price)} $currency';

      // Algolia SAR shape (overrides if available)
      final sarMap = _mapOf(priceObj['SAR']);
      if (sarMap != null) {
        final algoliaPrice = (sarMap['default'] as num?)?.toDouble();
        if (algoliaPrice != null) {
          price = algoliaPrice;
          formatted = _str(sarMap['default_formated']);
          formatted ??= '${_fmtPrice(price)} ر.س';
        }
      }
    }
    if (price == null && formatted == null) {
      // Last resort: top-level numeric price field
      final raw = rec['price'];
      if (raw is num) {
        price = raw.toDouble();
        formatted = '${_fmtPrice(price)} ر.س';
      }
    }

    // Slug for detail-page lookup
    final slug = _str(rec['slug']);

    // Rating
    final ratingRaw = rec['rating'];
    final rating = (ratingRaw is num) ? ratingRaw.toDouble() : null;

    // Image: RSC simple shape uses 'image', Algolia uses 'image_url'
    final imageUrl = _str(rec['image']) ?? _str(rec['image_url']);

    // Brand
    final brandRaw = rec['brand'];
    String? brand;
    if (brandRaw is String) {
      brand = brandRaw.trim();
    } else {
      brand = _stringList(brandRaw).firstOrNull;
    }

    // inStock: RSC simple shape → bool; Algolia → int 1/0
    bool inStock = true;
    final stockRaw = rec['inStock'] ?? rec['in_stock'];
    if (stockRaw is bool) {
      inStock = stockRaw;
    } else if (stockRaw is int) {
      inStock = stockRaw != 0;
    }

    // Usage lines (from Algolia-style records that have this at search level)
    final usage = _stringList(_mapOf(rec['usage'])?['arabic']);
    var ingredients = _stringList(rec['active_ingredients']);
    if (ingredients.isEmpty) ingredients = _stringList(rec['ingredients']);
    if (ingredients.isEmpty) ingredients = _stringList(rec['ingredient']);

    return NahdiProduct(
      sku: sku,
      nameAr: nameAr ?? nameEn ?? sku,
      nameEn: nameEn,
      slug: slug,
      priceSar: price,
      priceFormatted:
          formatted ?? (price != null ? '${_fmtPrice(price)} ر.س' : null),
      inStock: inStock,
      imageUrl: imageUrl,
      brandAr: brand,
      concentration: _str(rec['concentration']),
      rating: rating,
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
