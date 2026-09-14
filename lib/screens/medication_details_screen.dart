// Medication details screen — shows official registry info + live Saudi
// pharmacy pricing (Nahdi), usage, dosage, method, warnings, and ingredients.
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
  String _rxcui = '';
  String _fallbackName = '';
  String? _fallbackSynonym;
  bool _loading = true;
  bool _nahdiLoading = false;
  bool _staleOnly = false;
  bool _initialized = false;
  MedicationInfo? _info;
  List<NahdiProduct> _products = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        const {};
    _rxcui = args['rxcui'] as String? ?? '';
    _fallbackName = args['name'] as String? ?? '';
    _fallbackSynonym = args['synonym'] as String?;
    _load();
  }

  Future<void> _load() async {
    MedicationInfo? info;
    if (_rxcui.isNotEmpty) {
      info = await MedicationApiService().details(_rxcui);
    }
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
      _staleOnly = info != null && info.doseForm == null;
    });
    unawaited(_fetchNahdi());
  }

  Future<void> _fetchNahdi() async {
    if (!mounted) return;
    setState(() => _nahdiLoading = true);

    // Build ordered list of search candidate queries
    final candidates = <String>{};
    if (_info?.synonym != null && _info!.synonym!.trim().isNotEmpty) {
      candidates.add(_info!.synonym!.trim());
    }
    if (_fallbackSynonym != null && _fallbackSynonym!.trim().isNotEmpty) {
      candidates.add(_fallbackSynonym!.trim());
    }
    if (_info?.name != null && _info!.name.trim().isNotEmpty) {
      candidates.add(_info!.name.trim());
    }
    if (_fallbackName.trim().isNotEmpty) {
      candidates.add(_fallbackName.trim());
    }

    List<NahdiProduct> products = const [];
    for (final q in candidates) {
      products = await NahdiPriceService().search(q);
      if (products.isNotEmpty) break;

      // Try simplified search (first 1-2 words) if query has multiple words
      final words = q.split(RegExp(r'\s+'));
      if (words.length > 1) {
        final simplified = words.take(2).join(' ').trim();
        products = await NahdiPriceService().search(simplified);
        if (products.isNotEmpty) break;
        if (words.length > 2) {
          products = await NahdiPriceService().search(words.first);
          if (products.isNotEmpty) break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _products = products;
      _nahdiLoading = false;
    });
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
              prefillName: _info?.synonym ?? _info?.name ?? _fallbackName,
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
                const SizedBox(height: 16),
                _nahdiSection(strings),
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
    final synonym = _info?.synonym ?? _fallbackSynonym;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        synonym != null && synonym.isNotEmpty ? synonym : name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (synonym != null &&
                          synonym.isNotEmpty &&
                          name.isNotEmpty &&
                          name != synonym)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
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
                if (_rxcui.isNotEmpty)
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
    final topProduct = _products.firstOrNull;

    // Fallbacks from Nahdi product if main registry lacked them
    final indications =
        _info?.indications ??
        (topProduct != null && topProduct.usageLines.isNotEmpty
            ? topProduct.usageLines.join('\n• ')
            : null);
    final ingredients =
        _info?.ingredients ??
        (topProduct != null && topProduct.ingredients.isNotEmpty
            ? topProduct.ingredients.join('، ')
            : null);
    final dosage = _info?.dosage ?? topProduct?.dosage;
    final method = _info?.method ?? topProduct?.method;
    final form = strings.doseFormLabel(_info?.doseForm);
    final strength = _info?.strength ?? topProduct?.concentration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(strings.doseForm, form),
        _infoRow(strings.medStrength, strength),
        _infoRow(strings.ingredientsLabel, ingredients),
        _infoRow(strings.dosageLabel, dosage),
        _infoRow(strings.methodLabel, method),
        if (indications != null && indications.isNotEmpty)
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
                  const SizedBox(height: 8),
                  Text(
                    indications.startsWith('•')
                        ? indications
                        : '• $indications',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
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

  Widget _nahdiSection(AppStrings strings) {
    if (_nahdiLoading) {
      return Card(
        color: const Color(0xFF10B981).withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.nahdiSearching,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.local_pharmacy_outlined,
                size: 20,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.nahdiNotFound,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
          child: Row(
            children: [
              const Icon(
                Icons.local_pharmacy,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                strings.nahdiSectionTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        for (final product in _products.take(3)) _nahdiCard(strings, product),
      ],
    );
  }

  Widget _nahdiCard(AppStrings strings, NahdiProduct product) {
    return Card(
      color: const Color(0xFF10B981).withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
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
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              for (final line in product.usageLines.take(4))
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
            if (product.dosage != null && product.dosage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _nahdiDetailRow(strings.dosageLabel, product.dosage!),
            ],
            if (product.method != null && product.method!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _nahdiDetailRow(strings.methodLabel, product.method!),
            ],
            if (product.warnings != null && product.warnings!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _nahdiDetailRow(strings.warningsLabel, product.warnings!),
            ],
            if (product.ingredients.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${strings.ingredientsLabel}: ${product.ingredients.join('، ')}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              '${product.concentration ?? ''} ${strings.nahdiPriceNote}'.trim(),
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nahdiDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF047857),
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  Widget _infoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
