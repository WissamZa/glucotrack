// Pluggable drug-information sources.
//
// The default source is the bundled Saudi-market list (offline, Arabic
// search). The user can switch to international registries — RxNorm (NLM)
// or openFDA — both free with no developer registration.
//
// Selection is persisted in secure storage under [selectedSourceKey].
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../data/saudi_drugs.dart';
import '../models/medication_info.dart';

class DrugSources {
  DrugSources._();

  static const String saudi = 'saudi';
  static const String rxnorm = 'rxnorm';
  static const String openfda = 'openfda';
  static const List<String> all = [saudi, rxnorm, openfda];
  static const String defaultSource = saudi;

  static const String selectedSourceKey = 'drug_source_selected';

  static DrugSource byId(String id) {
    switch (id) {
      case rxnorm:
        return RxNormSource();
      case openfda:
        return OpenFdaSource();
      case saudi:
      default:
        return SaudiDrugSource();
    }
  }
}

abstract class DrugSource {
  /// Registry id — matches [DrugSources] constants.
  String get id;

  Future<List<MedicationInfo>> search(String query);

  Future<MedicationInfo?> details(String rxcui);
}

// ── 1) Bundled Saudi list (default, offline, Arabic search) ────────────────
class SaudiDrugSource extends DrugSource {
  @override
  String get id => DrugSources.saudi;

  @override
  Future<List<MedicationInfo>> search(String query) async {
    return searchSaudiDrugs(query).map((d) => d.toInfo()).toList();
  }

  @override
  Future<MedicationInfo?> details(String rxcui) async {
    final nativeId = MedicationInfo.nativeIdOf(rxcui);
    for (final d in kSaudiDrugs) {
      if (d.id == nativeId) return d.toInfo();
    }
    return null;
  }
}

// ── 2) RxNorm — international (NLM, free, no key) ──────────────────────────
class RxNormSource extends DrugSource {
  @override
  String get id => DrugSources.rxnorm;

  static const _host = 'rxnav.nlm.nih.gov';

  @override
  Future<List<MedicationInfo>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1) Rich name search first (results always carry names).
    try {
      final response = await http
          .get(Uri.https(_host, '/REST/drugs.json', {'name': q}))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final results = MedicationInfo.parseDrugsJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          fetchedAt: now,
        );
        if (results.isNotEmpty) return results;
      }
    } on Exception catch (e) {
      debugPrint('RxNorm drugs.json unavailable: $e');
    }

    // 2) Fuzzy fallback — approximateTerm candidates often lack a name, so
    // resolve the top few via allProperties (the bug that made search look
    // broken in v1.6).
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
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final group = json['approximateGroup'];
        final candidates = group is Map
            ? (group['candidate'] as List? ?? const [])
            : const [];
        final out = <MedicationInfo>[];
        final seen = <String>{};
        var resolved = 0;
        for (final raw in candidates) {
          final c = raw as Map<String, dynamic>;
          final rxcui = c['rxcui'] as String?;
          if (rxcui == null || rxcui.isEmpty || !seen.add(rxcui)) continue;
          final name = (c['name'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            out.add(
              MedicationInfo(
                source: DrugSources.rxnorm,
                rxcui: rxcui,
                name: name,
                synonym: (c['synonym'] as String?)?.trim(),
                tty: c['tty'] as String?,
                fetchedAt: now,
              ),
            );
          } else if (resolved < 3 && out.length < 8) {
            // Nameless candidate — resolve via allProperties.
            final info = await details(rxcui);
            resolved++;
            if (info != null) out.add(info);
          }
          if (out.length >= 8) break;
        }
        return out;
      }
    } on Exception catch (e) {
      debugPrint('RxNorm approximateTerm unavailable: $e');
    }
    return const [];
  }

  @override
  Future<MedicationInfo?> details(String rxcui) async {
    try {
      final response = await http
          .get(
            Uri.https(
              _host,
              '/REST/rxcui/${MedicationInfo.nativeIdOf(rxcui)}/allProperties.json',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return MedicationInfo.parseAllProperties(
          jsonDecode(response.body) as Map<String, dynamic>,
          rxcui,
        );
      }
    } on Exception catch (e) {
      debugPrint('RxNorm details unavailable: $e');
    }
    return null;
  }
}

// ── 3) openFDA — US drug labels (free, no key) ─────────────────────────────
class OpenFdaSource extends DrugSource {
  @override
  String get id => DrugSources.openfda;

  static const _host = 'api.fda.gov';

  static String? _first(dynamic list) {
    if (list is List && list.isNotEmpty) return list.first?.toString();
    return null;
  }

  Map<String, dynamic>? _firstOpenFda(Map<String, dynamic> result) {
    final openfda = result['openfda'];
    return openfda is Map<String, dynamic> ? openfda : null;
  }

  List<MedicationInfo> _parseResults(Map<String, dynamic> json) {
    final results = json['results'] as List? ?? const [];
    final out = <MedicationInfo>[];
    final seen = <String>{};
    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final fda = _firstOpenFda(raw);
      if (fda == null) continue;
      final brand = _first(fda['brand_name']) ?? _first(fda['generic_name']);
      final generic = _first(fda['generic_name']);
      if (brand == null || brand.isEmpty) continue;
      final form = _first(fda['dosage_form']);
      final route = _first(fda['route']);
      final id = 'openfda:${brand.toLowerCase()}-${generic ?? ''}';
      if (!seen.add(id)) continue;
      out.add(
        MedicationInfo(
          source: DrugSources.openfda,
          rxcui: id,
          name: brand,
          synonym: (generic != null && generic != brand) ? generic : null,
          doseForm: form,
          strength: route,
          tty: 'openfda',
          fetchedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (out.length >= 8) break;
    }
    return out;
  }

  @override
  Future<List<MedicationInfo>> search(String query) async {
    final q = query.trim().replaceAll('"', '');
    if (q.length < 2) return const [];
    try {
      final response = await http
          .get(
            Uri.https(_host, '/drug/label.json', {
              'search': 'openfda.brand_name:"$q" OR openfda.generic_name:"$q"',
              'limit': '10',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return _parseResults(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } on Exception catch (e) {
      debugPrint('openFDA search unavailable: $e');
    }
    return const [];
  }

  @override
  Future<MedicationInfo?> details(String rxcui) async {
    final native = MedicationInfo.nativeIdOf(rxcui);
    final name = native.split('-').first;
    if (name.isEmpty) return null;
    try {
      final response = await http
          .get(
            Uri.https(_host, '/drug/label.json', {
              'search': 'openfda.brand_name:"$name"',
              'limit': '1',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final parsed = _parseResults(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return parsed.isEmpty ? null : parsed.first;
      }
    } on Exception catch (e) {
      debugPrint('openFDA details unavailable: $e');
    }
    return null;
  }
}

// ── Selected-source persistence ────────────────────────────────────────────
class DrugSourceSelection {
  static final DrugSourceSelection _instance = DrugSourceSelection._internal();
  factory DrugSourceSelection() => _instance;
  DrugSourceSelection._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _cached;

  Future<String> selected() async {
    if (_cached != null) return _cached!;
    final raw = await _storage.read(key: DrugSources.selectedSourceKey);
    _cached = DrugSources.all.contains(raw) ? raw : DrugSources.defaultSource;
    return _cached!;
  }

  Future<void> select(String id) async {
    if (!DrugSources.all.contains(id)) return;
    _cached = id;
    await _storage.write(key: DrugSources.selectedSourceKey, value: id);
  }
}
