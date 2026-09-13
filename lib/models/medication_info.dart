// MedicationInfo — a drug entry from the RxNorm API (U.S. National Library
// of Medicine, public domain, no API key) cached offline in the
// `medication_cache` table (DB v5) so lookups work without re-requesting.
class MedicationInfo {
  /// Source registry id ('saudi' | 'rxnorm' | 'openfda') or an id embedded in
  /// [rxcui] via the 'source:id' prefix convention (see DrugSources).
  final String source;
  final String rxcui; // RxNorm concept id, or 'source:id' for other sources
  final String name;
  final String? synonym;
  final String? doseForm; // e.g. "Tablet", "Oral Solution"
  final String? strength; // e.g. "500 mg/1"
  final String? tty; // term type: SBD (brand) / SCDC / IN ...
  final String? indications; // دواعي الاستخدام (openFDA / Saudi bundled)
  final String? ingredients; // active ingredients
  final String? dosage; // الجرعة الموصى بها
  final String? method; // طريقة الاستخدام
  final bool? otc; // true = sold without prescription; null = unknown
  final int fetchedAt; // epoch ms — cache freshness

  const MedicationInfo({
    this.source = 'rxnorm',
    required this.rxcui,
    required this.name,
    this.synonym,
    this.doseForm,
    this.strength,
    this.tty,
    this.indications,
    this.ingredients,
    this.dosage,
    this.method,
    this.otc,
    required this.fetchedAt,
  });

  /// Cache entries older than this are refreshed on next detail lookup.
  static const cacheTtlDays = 30;

  bool get isFresh =>
      DateTime.now().millisecondsSinceEpoch - fetchedAt <
      cacheTtlDays * 24 * 60 * 60 * 1000;

  /// Resolves which source registry an id belongs to (prefix convention:
  /// 'saudi:xxx', 'openfda:xxx', or a bare RxNorm id).
  static String sourceOf(String rxcui) {
    for (final src in const ['saudi', 'openfda', 'rxnorm']) {
      if (rxcui.startsWith('$src:')) return src;
    }
    return 'rxnorm';
  }

  /// Strips the 'source:' prefix, returning the registry-native id.
  static String nativeIdOf(String rxcui) {
    final i = rxcui.indexOf(':');
    return i > 0 ? rxcui.substring(i + 1) : rxcui;
  }

  Map<String, dynamic> toDb() => {
    'source': source,
    'rxcui': rxcui,
    'name': name,
    'synonym': synonym,
    'dose_form': doseForm,
    'strength': strength,
    'tty': tty,
    'indications': indications,
    'ingredients': ingredients,
    'dosage': dosage,
    'method': method,
    'otc': (otc == null) ? null : (otc! ? 1 : 0),
    'fetched_at': fetchedAt,
  };

  factory MedicationInfo.fromDb(Map<String, dynamic> m) => MedicationInfo(
    source: (m['source'] as String?) ?? 'rxnorm',
    rxcui: m['rxcui'] as String,
    name: m['name'] as String,
    synonym: m['synonym'] as String?,
    doseForm: m['dose_form'] as String?,
    strength: m['strength'] as String?,
    tty: m['tty'] as String?,
    indications: m['indications'] as String?,
    ingredients: m['ingredients'] as String?,
    dosage: m['dosage'] as String?,
    method: m['method'] as String?,
    otc: m['otc'] == null ? null : (m['otc'] as int) == 1,
    fetchedAt: m['fetched_at'] as int,
  );

  factory MedicationInfo.fromRxNormProperties(
    String rxcui,
    Map<String, String> props, {
    int? fetchedAt,
  }) {
    String? pick(bool Function(String key) test) {
      for (final entry in props.entries) {
        if (test(entry.key.toLowerCase())) return entry.value;
      }
      return null;
    }

    return MedicationInfo(
      rxcui: rxcui,
      name: props['name'] ?? props['str'] ?? rxcui,
      synonym: props['synonym'],
      doseForm: pick((k) => k.contains('dose form') || k == 'doseform'),
      strength: pick((k) => k.contains('strength')),
      tty: props['tty'],
      fetchedAt: fetchedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Parse the RxNorm `approximateTerm.json` response into suggestions.
  static List<MedicationInfo> parseApproximateTerms(
    Map<String, dynamic> json, {
    required int fetchedAt,
  }) {
    final group = json['approximateGroup'];
    final candidates = group is Map
        ? (group['candidate'] as List? ?? const [])
        : const [];
    final out = <MedicationInfo>[];
    final seen = <String>{};
    for (final raw in candidates) {
      final c = raw as Map<String, dynamic>;
      final rxcui = c['rxcui'] as String?;
      final name = (c['name'] as String?)?.trim();
      if (rxcui == null || rxcui.isEmpty || name == null || name.isEmpty) {
        continue;
      }
      if (!seen.add(rxcui)) continue;
      out.add(
        MedicationInfo(
          rxcui: rxcui,
          name: name,
          synonym: (c['synonym'] as String?)?.trim(),
          tty: c['tty'] as String?,
          fetchedAt: fetchedAt,
        ),
      );
      if (out.length >= 8) break;
    }
    return out;
  }

  /// Parse the RxNorm `drugs.json` response (rich search results).
  static List<MedicationInfo> parseDrugsJson(
    Map<String, dynamic> json, {
    required int fetchedAt,
  }) {
    final group = json['drugGroup'];
    final groups = group is Map
        ? (group['conceptGroup'] as List? ?? const [])
        : const [];
    final out = <MedicationInfo>[];
    final seen = <String>{};
    for (final g in groups) {
      final props = g is Map
          ? (g['conceptProperties'] as List? ?? const [])
          : const [];
      for (final raw in props) {
        final c = raw as Map<String, dynamic>;
        final rxcui = c['rxcui'] as String?;
        final name = (c['name'] as String?)?.trim();
        if (rxcui == null || rxcui.isEmpty || name == null || name.isEmpty) {
          continue;
        }
        if (!seen.add(rxcui)) continue;
        out.add(
          MedicationInfo(
            source: 'rxnorm',
            rxcui: rxcui,
            name: name,
            synonym: (c['synonym'] as String?)?.trim(),
            tty: c['tty'] as String?,
            fetchedAt: fetchedAt,
          ),
        );
        if (out.length >= 8) return out;
      }
    }
    return out;
  }

  /// Parse the RxNorm `rxcui/{id}/allProperties.json` response.
  static MedicationInfo? parseAllProperties(
    Map<String, dynamic> json,
    String rxcui,
  ) {
    final props =
        (((json['propConceptGroup'] as Map<String, dynamic>?) ??
                {})['propConcept']
            as List?) ??
        const [];
    final map = <String, String>{};
    for (final raw in props) {
      final p = raw as Map<String, dynamic>;
      final key = p['propName'] as String?;
      final value = p['propValue'] as String?;
      if (key != null && value != null && value.isNotEmpty) {
        map[key] = value;
      }
    }
    if (map.isEmpty) return null;
    return MedicationInfo.fromRxNormProperties(rxcui, map);
  }
}
