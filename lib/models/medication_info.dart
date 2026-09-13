// MedicationInfo — a drug entry from the RxNorm API (U.S. National Library
// of Medicine, public domain, no API key) cached offline in the
// `medication_cache` table (DB v5) so lookups work without re-requesting.
class MedicationInfo {
  final String rxcui; // RxNorm concept id
  final String name;
  final String? synonym;
  final String? doseForm; // e.g. "Tablet", "Oral Solution"
  final String? strength; // e.g. "500 mg/1"
  final String? tty; // term type: SBD (brand) / SCDC / IN ...
  final int fetchedAt; // epoch ms — cache freshness

  const MedicationInfo({
    required this.rxcui,
    required this.name,
    this.synonym,
    this.doseForm,
    this.strength,
    this.tty,
    required this.fetchedAt,
  });

  /// Cache entries older than this are refreshed on next detail lookup.
  static const cacheTtlDays = 30;

  bool get isFresh =>
      DateTime.now().millisecondsSinceEpoch - fetchedAt <
      cacheTtlDays * 24 * 60 * 60 * 1000;

  Map<String, dynamic> toDb() => {
    'rxcui': rxcui,
    'name': name,
    'synonym': synonym,
    'dose_form': doseForm,
    'strength': strength,
    'tty': tty,
    'fetched_at': fetchedAt,
  };

  factory MedicationInfo.fromDb(Map<String, dynamic> m) => MedicationInfo(
    rxcui: m['rxcui'] as String,
    name: m['name'] as String,
    synonym: m['synonym'] as String?,
    doseForm: m['dose_form'] as String?,
    strength: m['strength'] as String?,
    tty: m['tty'] as String?,
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
