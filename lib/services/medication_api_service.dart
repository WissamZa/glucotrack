// Medication lookup via the RxNorm REST API (U.S. National Library of
// Medicine) — free, public domain, NO API key or developer registration.
//
// Strategy: local cache (medication_cache table, DB v5) first, network
// second. Suggestions come from `approximateTerm.json`; full details from
// `rxcui/{id}/allProperties.json`. Every network result is written to the
// cache so subsequent lookups (and the details page) work offline.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import '../models/medication_info.dart';

class MedicationApiService {
  static final MedicationApiService _instance =
      MedicationApiService._internal();
  factory MedicationApiService() => _instance;
  MedicationApiService._internal();

  static const _host = 'rxnav.nlm.nih.gov';
  final _db = DatabaseHelper();

  /// Search medications by (partial) name. Local cache results are always
  /// included; network results are merged in when reachable. Safe to call
  /// offline — it simply returns cache-only results.
  Future<List<MedicationInfo>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final results = <MedicationInfo>[];
    final seen = <String>{};

    // 1) Offline cache — instant and always available.
    for (final cached in await _db.searchMedicationCache(q)) {
      if (seen.add(cached.rxcui)) results.add(cached);
    }

    // 2) RxNorm approximate matching (best-effort; network errors ignored).
    try {
      final response = await http
          .get(
            Uri.https(_host, '/REST/approximateTerm.json', {
              'term': q,
              'maxEntries': '8',
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final suggestions = MedicationInfo.parseApproximateTerms(
          (jsonDecode(response.body) as Map<String, dynamic>),
          fetchedAt: now,
        );
        for (final info in suggestions) {
          if (seen.add(info.rxcui)) {
            results.add(info);
            await _db.upsertMedicationCache(info);
          }
        }
      }
    } on Exception catch (e) {
      debugPrint('RxNorm search unavailable: $e');
    }

    return results;
  }

  /// Full details for a medication. Cache-first (30-day freshness); falls
  /// back to stale cache when offline. Returns null when nothing is known.
  Future<MedicationInfo?> details(String rxcui) async {
    final cached = await _db.getMedicationFromCache(rxcui);
    if (cached != null && cached.isFresh && cached.doseForm != null) {
      return cached;
    }

    try {
      final response = await http
          .get(Uri.https(_host, '/REST/rxcui/$rxcui/allProperties.json'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final info = MedicationInfo.parseAllProperties(
          jsonDecode(response.body) as Map<String, dynamic>,
          rxcui,
        );
        if (info != null) {
          await _db.upsertMedicationCache(info);
          return info;
        }
      }
    } on Exception catch (e) {
      debugPrint('RxNorm details unavailable: $e');
    }

    // Offline (or parse failure) → stale cache is better than nothing.
    return cached;
  }
}
