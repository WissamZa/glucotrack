// Medication details screen — drug information from the selected source
// (bundled Saudi list / RxNorm / openFDA), served cache-first so repeat
// lookups work offline. Shows active ingredients, indications, prescription
// status and an approximate Nahdi Pharmacy price when available.
import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/medication_info.dart';
import '../services/medication_api_service.dart';
import '../services/nahdi_price_service.dart';
import '../widgets/reminder_editor.dart';
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
  bool _staleOnly = false;
  List<NahdiProduct> _products = const [];

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
      // Search-stage entries carry no dose form — usually means the network
      // lookup failed and we fell back to cached data.
      _staleOnly = info != null && info.doseForm == null;
    });
    unawaited(_fetchNahdi());
  }

  Future<void> _fetchNahdi() async {
    final query = _info?.name ?? _fallbackName;
    if (query.isEmpty) return;
    final products = await NahdiPriceService().search(query);
    if (!mounted) return;
    setState(() => _products = products);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.medicationDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: strings.addReminder,
            onPressed: () => showReminderEditor(
              context,
              prefillName: _info?.name ?? _fallbackName,
              prefillRxcui: _rxcui,
              prefillFormKey: _info?.doseForm,
            ),
          ),
        ],
      ),
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
                _headerCard(strings),
                const SizedBox(height: 12),
                _detailsSection(strings),
                if (_products.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final product in _products.take(3))
                    _nahdiCard(strings, product),
                ],
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

  Widget _headerCard(AppStrings strings) {
    final name = _info?.name ?? _fallbackName;
    return Card(
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
                if (_info?.otc != null)
                  _prescriptionBadge(strings, _info!.otc!)
                else
                  const SizedBox.shrink(),
                const Spacer(),
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
                    strings.sourceLabel(MedicationInfo.sourceOf(_rxcui)),
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
    );
  }

  Widget _prescriptionBadge(AppStrings strings, bool otc) {
    final color = otc ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(otc ? Icons.redeem : Icons.receipt_long, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            otc ? strings.otcBadge : strings.rxBadge,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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

  Widget _detailsSection(AppStrings strings) {
    if (_info == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            strings.noSuggestions,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      );
    }
    final info = _info!;
    final form = strings.doseFormLabel(info.doseForm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(strings.medSynonym, info.synonym),
        _infoRow(strings.doseForm, form),
        _infoRow(strings.medStrength, info.strength),
        _infoRow(strings.ingredientsLabel, info.ingredients),
        _infoRow(strings.dosageLabel, info.dosage),
        _infoRow(strings.methodLabel, info.method),
        if (info.indications != null && info.indications!.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.indicationsLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.indications!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (info.indications == null || info.ingredients == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              strings.notFromSource,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ),
        if (_staleOnly)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              strings.noSuggestions,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }

  Widget _nahdiCard(AppStrings strings, NahdiProduct product) {
    return Card(
      color: const Color(0xFF10B981).withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.local_pharmacy,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.local_pharmacy,
                            color: Color(0xFF10B981),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            strings.nahdiPrice,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.priceFormatted ??
                                (product.priceSar != null
                                    ? '${product.priceSar} ر.س'
                                    : strings.priceUnavailable),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: product.inStock
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product.inStock
                        ? strings.inStockLabel
                        : strings.outOfStockLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: product.inStock
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            if (product.usageLines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                strings.usageLinesLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              for (final line in product.usageLines.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (product.dosage != null) ...[
              const SizedBox(height: 8),
              _nahdiDetailRow(strings.dosageLabel, product.dosage!),
            ],
            if (product.method != null) ...[
              const SizedBox(height: 4),
              _nahdiDetailRow(strings.methodLabel, product.method!),
            ],
            if (product.ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${strings.ingredientsLabel}: ${product.ingredients.join('، ')}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ),
            Text(
              '${product.concentration ?? ''} ${strings.nahdiPriceNote}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nahdiDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

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
