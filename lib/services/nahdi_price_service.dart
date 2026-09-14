// Nahdi Pharmacy lookup (nahdionline.com — largest Saudi chain).
//
// Search: requests the search page to get product records from
// InstantSearchInitialResults (and falls back to RSC stream / Algolia).
//
// Details: for top products, we fetch the individual product page to extract
// dosage (الجرعة الموصى بها), method of use (طريقة الاستخدام), warnings, and
// active ingredients.
//
// Degrades gracefully when offline or blocked.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NahdiProduct {
  final String sku;
  final String nameAr;
  final String? nameEn;
  final String? slug;
  final String? url;
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
  final String? warnings;

  const NahdiProduct({
    required this.sku,
    required this.nameAr,
    this.nameEn,
    this.slug,
    this.url,
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
    this.warnings,
  });

  NahdiProduct copyWithDetails({
    List<String>? usageLines,
    List<String>? ingredients,
    String? dosage,
    String? method,
    String? warnings,
  }) => NahdiProduct(
    sku: sku,
    nameAr: nameAr,
    nameEn: nameEn,
    slug: slug,
    url: url,
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
    warnings: warnings ?? this.warnings,
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
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'ar-SA,ar;q=0.9,en;q=0.8',
  };

  /// Best-effort product lookup. Returns an empty list when offline/blocked.
  /// Also enriches top products with per-product details (dosage, method, etc.)
  /// from the product detail page.
  Future<List<NahdiProduct>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final cacheKey = q.toLowerCase();
    final cached = _memoryCache[cacheKey];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(
        '$_baseUrl$_searchPath?query=${Uri.encodeComponent(q)}',
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final products = parseProducts(body);
      if (products.isEmpty) return const [];

      // Enrich top 3 products with detail page data (parallel).
      final topEnriched = await Future.wait(
        products.take(3).map((p) => _fetchProductDetails(p)),
      );
      final enriched = [...topEnriched, ...products.skip(3)];
      _memoryCache[cacheKey] = enriched;
      return enriched;
    } on Exception catch (e) {
      debugPrint('Nahdi lookup unavailable: $e');
      return const [];
    }
  }

  /// Fetch the individual product page and extract detail fields.
  Future<NahdiProduct> _fetchProductDetails(NahdiProduct product) async {
    final targetUrl =
        product.url ??
        (product.slug != null ? '$_baseUrl/ar-sa/${product.slug}' : null);
    if (targetUrl == null || targetUrl.isEmpty) return product;

    try {
      final fullUrl = targetUrl.startsWith('http')
          ? targetUrl
          : '$_baseUrl$targetUrl';
      final response = await http
          .get(Uri.parse(fullUrl), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return product;
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _extractProductDetails(product, body);
    } on Exception catch (e) {
      debugPrint('Nahdi product detail unavailable for ${product.nameAr}: $e');
      return product;
    }
  }

  /// Parse the HTML/RSC payload for a product detail page and extract
  /// usage, method, dosage, warnings and ingredients.
  static NahdiProduct _extractProductDetails(
    NahdiProduct product,
    String html,
  ) {
    final cleanedHtml = html
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?<\/style>',
            dotAll: true,
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?<\/script>',
            dotAll: true,
            caseSensitive: false,
          ),
          '',
        );

    final unescaped = cleanedHtml
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&');

    String? dosage = product.dosage;
    String? method = product.method;
    String? warnings = product.warnings;
    final extraUsage = List<String>.from(product.usageLines);
    final extraIngredients = List<String>.from(product.ingredients);

    const sectionsToStop = [
      'كيفية تخزين',
      'التحذيرات والاحتياطات',
      'التحذيرات والإحتياطات',
      'الآثار الجانبية',
      'الأدوية الأخرى',
      'ما هو ',
      'لا تتناول',
      'المكونات',
    ];

    // 1. Method / Administration / Dosage instructions
    if (method == null || dosage == null) {
      final methodPattern = RegExp(
        r'<strong[^>]*>(?:كيفية تناول|كيفية الاستخدام|كيفية الإستخدام|طريقة الاستخدام|طريقة الإستخدام|How to use)[^<]*<\/strong>(?:<strong[^>]*>[:\s]*<\/strong>)?(.*?)(?=(?:<strong[^>]*>(?:' +
            sectionsToStop.map(RegExp.escape).join('|') +
            r')|<div class="data item|<div class="product-info-detailed"|<\/div>\s*<\/div>\s*<\/div>|$))',
        dotAll: true,
        caseSensitive: false,
      );
      final m = methodPattern.firstMatch(unescaped);
      if (m != null) {
        final text = _cleanHtmlBlock(m.group(1) ?? '');
        if (text.isNotEmpty) {
          method ??= text;
        }
      }
    }

    // 2. Specific Dosage block if separate
    if (dosage == null) {
      final dosagePattern = RegExp(
        r'<strong[^>]*>(?:الجرعة الموصى بها|الجرعة وطريقة الاستعمال|الجرعة|Dosage)[^<]*<\/strong>(?:<strong[^>]*>[:\s]*<\/strong>)?(.*?)(?=(?:<strong[^>]*>(?:' +
            sectionsToStop.map(RegExp.escape).join('|') +
            r')|<div class="data item|<div class="product-info-detailed"|<\/div>\s*<\/div>\s*<\/div>|$))',
        dotAll: true,
        caseSensitive: false,
      );
      final m = dosagePattern.firstMatch(unescaped);
      if (m != null) {
        final text = _cleanHtmlBlock(m.group(1) ?? '');
        if (text.isNotEmpty) {
          dosage = text;
        }
      }
    }

    // 3. Warnings block
    if (warnings == null) {
      final warnPattern = RegExp(
        r'<strong[^>]*>(?:التحذيرات والاحتياطات|التحذيرات والإحتياطات|تحذيرات|Warnings)[^<]*<\/strong>(?:<strong[^>]*>[:\s]*<\/strong>)?(.*?)(?=(?:<strong[^>]*>(?:الآثار الجانبية|الأدوية الأخرى|كيفية تخزين)|<div class="data item|<div class="product-info-detailed"|<\/div>\s*<\/div>\s*<\/div>|$))',
        dotAll: true,
        caseSensitive: false,
      );
      final m = warnPattern.firstMatch(unescaped);
      if (m != null) {
        final text = _cleanHtmlBlock(m.group(1) ?? '');
        if (text.isNotEmpty) {
          warnings = text;
        }
      }
    }

    // 4. Ingredients from specifications tab if empty
    if (extraIngredients.isEmpty) {
      final specIdx = unescaped.indexOf('specifications-tab');
      if (specIdx != -1) {
        final specBlock = unescaped.substring(
          specIdx,
          (specIdx + 1500).clamp(0, unescaped.length),
        );
        final ingMatch = RegExp(r'المكونات:\s*([^<]+)').firstMatch(specBlock);
        if (ingMatch != null) {
          final ingText = ingMatch.group(1)?.trim() ?? '';
          if (ingText.isNotEmpty) {
            extraIngredients.addAll(
              ingText
                  .split(RegExp(r'[\-—–,،]+'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty),
            );
          }
        }
      }
    }

    return product.copyWithDetails(
      usageLines: extraUsage.isNotEmpty ? extraUsage : null,
      ingredients: extraIngredients.isNotEmpty ? extraIngredients : null,
      dosage: dosage,
      method: method,
      warnings: warnings,
    );
  }

  static String _cleanHtmlBlock(String raw) {
    var s = raw;
    final metaEnd = s.indexOf(RegExp(r'["\x27]\s*\/?>'));
    if (metaEnd != -1) {
      s = s.substring(0, metaEnd);
    }
    return s
        .replaceAll(RegExp(r'<li[^>]*>'), '• ')
        .replaceAll(RegExp(r'<\/li>'), '\n')
        .replaceAll(RegExp(r'<br\s*\/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();
  }

  // ── Search result parsing ──────────────────────────────────────────────────

  /// Parses search response from HTML or RSC stream.
  static List<NahdiProduct> parseProducts(String payload) {
    // 1) Primary: parse InstantSearchInitialResults embedded in Nahdi's search HTML
    const marker = 'window[Symbol.for("InstantSearchInitialResults")]';
    final idx = payload.indexOf(marker);
    if (idx != -1) {
      try {
        final eqIdx = payload.indexOf('=', idx);
        final scriptEnd = payload.indexOf('</script>', eqIdx);
        if (scriptEnd != -1) {
          var jsonStr = payload.substring(eqIdx + 1, scriptEnd).trim();
          if (jsonStr.endsWith(';')) {
            jsonStr = jsonStr.substring(0, jsonStr.length - 1).trim();
          }
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final prodAr = data['prod_ar_products'] as Map<String, dynamic>?;
          final results = prodAr?['results'] as List<dynamic>?;
          final firstRes = (results != null && results.isNotEmpty)
              ? results[0] as Map<String, dynamic>?
              : null;
          final hits = firstRes?['hits'] as List<dynamic>?;
          if (hits != null && hits.isNotEmpty) {
            final out = <NahdiProduct>[];
            final seen = <String>{};
            for (final hit in hits) {
              if (hit is! Map<String, dynamic>) continue;
              final p = _fromHit(hit);
              if (p != null && seen.add(p.sku)) {
                out.add(p);
                if (out.length >= 8) break;
              }
            }
            if (out.isNotEmpty) return out;
          }
        }
      } on Exception catch (e) {
        debugPrint('Failed to parse InstantSearchInitialResults: $e');
      }
    }

    // 2) Fallback: balanced brace scanner for RSC stream / JSON records
    return _parseWithBraceScanner(payload);
  }

  static NahdiProduct? _fromHit(Map<String, dynamic> hit) {
    final sku = hit['sku']?.toString();
    if (sku == null || sku.isEmpty) return null;

    final storeAr = hit['store_ar'] is Map ? hit['store_ar'] as Map : null;
    final storeEn = hit['store_en'] is Map ? hit['store_en'] as Map : null;

    final nameAr =
        (storeAr?['name'] ?? hit['name'] ?? storeEn?['name'])?.toString() ??
        sku;
    final nameEn = (storeEn?['name'])?.toString();

    // Price
    double? price;
    String? formatted;
    final priceObj = hit['price'];
    if (priceObj is Map) {
      final sar = priceObj['SAR'];
      if (sar is Map) {
        final def = sar['default'];
        if (def is num) price = def.toDouble();
        formatted = sar['default_formated']?.toString();
      }
      if (price == null && priceObj['value'] is num) {
        price = (priceObj['value'] as num).toDouble();
        final cur = priceObj['currency']?.toString() ?? 'SAR';
        formatted = '${_fmtPrice(price)} $cur';
      }
    } else if (priceObj is num) {
      price = priceObj.toDouble();
      formatted = '${_fmtPrice(price)} ر.س';
    }

    final stockRaw = hit['in_stock'] ?? hit['inStock'];
    final inStock = stockRaw == 1 || stockRaw == true || stockRaw == '1';

    final imageUrl = (hit['image_url'] ?? hit['thumbnail_url'] ?? hit['image'])
        ?.toString();
    final brand =
        (hit['manufacturer'] ?? storeAr?['manufacturer'] ?? hit['brand'])
            ?.toString();

    final usageLines = <String>[];
    final usageObj = hit['usage'];
    if (usageObj is Map) {
      final arList = usageObj['arabic'];
      if (arList is List) {
        for (final item in arList) {
          if (item != null && item.toString().trim().isNotEmpty) {
            usageLines.add(item.toString().trim());
          }
        }
      }
    }

    final ingredients = <String>[];
    final ingRaw =
        hit['ingredient'] ?? hit['active_ingredients'] ?? hit['ingredients'];
    if (ingRaw is String && ingRaw.trim().isNotEmpty) {
      ingredients.addAll(
        ingRaw
            .split(RegExp(r'[\-—–,،]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    } else if (ingRaw is List) {
      for (final item in ingRaw) {
        if (item != null && item.toString().trim().isNotEmpty) {
          ingredients.add(item.toString().trim());
        }
      }
    }

    final url = hit['url']?.toString();
    final slug = hit['url_key']?.toString() ?? hit['slug']?.toString();

    return NahdiProduct(
      sku: sku,
      nameAr: nameAr,
      nameEn: nameEn,
      slug: slug,
      url: url,
      priceSar: price,
      priceFormatted:
          formatted ?? (price != null ? '${_fmtPrice(price)} ر.س' : null),
      inStock: inStock,
      imageUrl: imageUrl,
      brandAr: brand,
      concentration: hit['concentration']?.toString(),
      rating: hit['rating'] is num ? (hit['rating'] as num).toDouble() : null,
      usageLines: usageLines,
      ingredients: ingredients,
    );
  }

  static List<NahdiProduct> _parseWithBraceScanner(String payload) {
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
      if (out.length >= 8) break;
    }
    return out;
  }

  static NahdiProduct? _decodeRecord(String raw) {
    final rec = _tryDecode(raw);
    if (rec == null) return null;
    return _fromHit(rec);
  }

  static String _fmtPrice(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

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
}
