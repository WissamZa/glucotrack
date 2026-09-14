// Medication lookup facade — search + details through the SELECTED drug
// source (bundled Saudi list by default; RxNorm / openFDA selectable),
// with a source-aware offline cache in front of every lookup.
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/medication_info.dart';
import 'drug_source.dart';

class MedicationApiService {
  static final MedicationApiService _instance =
      MedicationApiService._internal();
  factory MedicationApiService() => _instance;
  MedicationApiService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  /// Search via the selected source. Local cache results for that source are
  /// always included; network errors degrade to cache-only (never throw).
  Future<List<MedicationInfo>> search(String query, {String? source}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final srcId = source ?? await DrugSourceSelection().selected();
    final src = DrugSources.byId(srcId);

    final results = <MedicationInfo>[];
    final seen = <String>{};

    // 1) Offline cache — instant and always available.
    for (final cached in await _db.searchMedicationCache(srcId, q)) {
      if (seen.add(cached.rxcui)) results.add(cached);
    }

    // 2) Source search (best-effort; offline -> cache-only results).
    try {
      for (final info in await src.search(q)) {
        if (seen.add(info.rxcui)) {
          results.add(info);
          await _db.upsertMedicationCache(info);
        }
      }
    } on Exception catch (e) {
      debugPrint('Drug source "$srcId" search unavailable: $e');
    }

    return results;
  }

  /// Details for one medication. Cache-first (bundled entries are always
  /// fresh; online entries refresh after 30 days), network fallback, and a
  /// stale-cache last resort. Returns null when nothing is known.
  Future<MedicationInfo?> details(String rxcui) async {
    final srcId = MedicationInfo.sourceOf(rxcui);
    final src = DrugSources.byId(srcId);

    // Bundled Saudi list is local, authoritative, and always fresh.
    if (srcId == DrugSources.saudi) {
      final saudi = await src.details(rxcui);
      if (saudi != null) {
        try {
          await _db.upsertMedicationCache(saudi);
        } on Exception catch (_) {}
        return saudi;
      }
    }

    final cached = await _db.getMedicationFromCache(srcId, rxcui);
    if (cached != null && cached.isFresh && cached.doseForm != null) {
      return cached;
    }

    try {
      final info = await src.details(rxcui);
      if (info != null) {
        await _db.upsertMedicationCache(info);
        return info;
      }
    } on Exception catch (e) {
      debugPrint('Drug source "$srcId" details unavailable: $e');
    }

    return cached; // stale cache is better than nothing
  }

  /// All cached medications across sources (Medications tab browse view).
  Future<List<MedicationInfo>> cached({int limit = 20}) =>
      _db.allCachedMedications(limit: limit);

  // -- Source selection passthrough ----------------------------------------
  Future<String> selectedSource() => DrugSourceSelection().selected();
  Future<void> selectSource(String id) => DrugSourceSelection().select(id);
}
