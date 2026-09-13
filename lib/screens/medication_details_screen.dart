// Medication details screen — drug information from the RxNorm API
// (U.S. National Library of Medicine, public domain, no key), served
// cache-first so repeat lookups work offline.
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/medication_info.dart';
import '../services/medication_api_service.dart';
import '../widgets/screen_padding.dart';

class MedicationDetailsScreen extends StatefulWidget {
  const MedicationDetailsScreen({super.key});

  @override
  State<MedicationDetailsScreen> createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  late final String _rxcui;
  late final String _fallbackName;
  MedicationInfo? _info;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const {};
    _rxcui = args['rxcui'] as String? ?? '';
    _fallbackName = args['name'] as String? ?? '';
    _load();
  }

  Future<void> _load() async {
    final info = await MedicationApiService().details(_rxcui);
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
      // No dose form in the result usually means the network lookup failed
      // and we fell back to a search-stage cache entry.
      _offline = info != null && info.doseForm == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final name = _info?.name ?? _fallbackName;

    return Scaffold(
      appBar: AppBar(title: Text(strings.medicationDetails)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                pushedScreenBottomClearance(context),
              ),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.medication_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _typeChip(strings, _info?.tty),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                strings.sourceLabel(
                                  MedicationInfo.sourceOf(_rxcui),
                                ),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_info != null) ...[
                  _infoRow(strings.medSynonym, _info!.synonym),
                  _infoRow(strings.doseForm, _info!.doseForm),
                  _infoRow(strings.medStrength, _info!.strength),
                ] else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        strings.noSuggestions,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                if (_offline)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      strings.noSuggestions,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  strings.medSourceRxNorm,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
    );
  }

  Widget _typeChip(AppStrings strings, String? tty) {
    // SBD/BPCK/… = brand names; IN/SCD/… = generic (clinical) names.
    final isBrand =
        tty != null && (tty.startsWith('SB') || tty.startsWith('BP'));
    final label = isBrand ? strings.medTypeBrand : strings.medTypeGeneric;
    final color = isBrand ? const Color(0xFF8B5CF6) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          dense: true,
          title: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
