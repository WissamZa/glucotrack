// Medications tab — a general drug library: search across the selected
// source (bundled Saudi list by default; RxNorm / openFDA selectable),
// browse previously-looked-up drugs and the user's own medications.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.dart';
import '../models/medication_info.dart';
import '../models/reminder.dart';
import '../providers/providers.dart';
import '../services/drug_source.dart';
import '../services/medication_api_service.dart';
import '../widgets/reminder_editor.dart';
import '../widgets/screen_padding.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _searchCtrl = TextEditingController();
  final _api = MedicationApiService();
  Timer? _debounce;

  String _source = DrugSources.defaultSource;
  List<MedicationInfo> _results = const [];
  List<MedicationInfo> _cached = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadBrowseData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBrowseData() async {
    final source = await _api.selectedSource();
    final cached = await _api.cached();
    if (!mounted) return;
    setState(() {
      _source = source;
      _cached = cached;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results = await _api.search(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  Future<void> _selectSource(String id) async {
    await _api.selectSource(id);
    if (!mounted) return;
    setState(() {
      _source = id;
      _results = const [];
    });
    _onSearchChanged(_searchCtrl.text); // re-run if a query is present
  }

  void _openDetails(MedicationInfo info) {
    Navigator.of(context).pushNamed(
      '/medication-details',
      arguments: {'rxcui': info.rxcui, 'name': info.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final remProv = context.watch<RemindersProvider>();
    final userMeds = remProv.reminders
        .where((r) => r.kind == ReminderKind.medication)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.medicationsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          tabBarBottomClearance(context),
        ),
        children: [
          // Search field
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: strings.medsSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Source selector
          Text(
            strings.drugSourceLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final id in DrugSources.all)
                ChoiceChip(
                  label: Text(
                    strings.sourceLabel(id),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: _source == id,
                  onSelected: (_) => _selectSource(id),
                  tooltip: strings.sourceDesc(id),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Results (search mode)
          if (_searchCtrl.text.trim().length >= 2) ...[
            if (_results.isEmpty && !_searching)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.noResultsSourceHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._results.map(
                (info) =>
                    _DrugTile(info: info, onTap: () => _openDetails(info)),
              ),
          ]
          // Browse mode (no query)
          else ...[
            if (userMeds.isNotEmpty) ...[
              _sectionTitle(strings.yourMedications),
              for (final r in userMeds.take(6))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(r.label, style: const TextStyle(fontSize: 13.5)),
                  subtitle: r.doseAmount != null
                      ? Text(
                          '${_fmt(r.doseAmount!)} ${strings.doseFormLabel(r.doseForm) ?? ''}',
                          style: const TextStyle(fontSize: 11.5),
                        )
                      : null,
                  onTap: r.rxcui != null
                      ? () => _openDetails(
                          MedicationInfo(
                            source: MedicationInfo.sourceOf(r.rxcui!),
                            rxcui: r.rxcui!,
                            name: r.label,
                            fetchedAt: 0,
                          ),
                        )
                      : null,
                ),
            ],
            if (_cached.isNotEmpty) ...[
              _sectionTitle(strings.fromCache),
              for (final info in _cached.take(10))
                _DrugTile(info: info, onTap: () => _openDetails(info)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );

  String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();
}

class _DrugTile extends StatelessWidget {
  final MedicationInfo info;
  final VoidCallback onTap;

  const _DrugTile({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final form = strings.doseFormLabel(info.doseForm);
    final subtitle = [
      if (info.synonym != null && info.synonym != info.name) info.synonym!,
      ?form,
      ?info.strength,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
          ),
          title: Text(
            info.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle.isEmpty
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.alarm_add, size: 20),
                color: Theme.of(context).colorScheme.primary,
                tooltip: strings.addReminder,
                onPressed: () => showReminderEditor(
                  context,
                  prefillName: info.name,
                  prefillRxcui: info.rxcui,
                  prefillFormKey: _formKeyOf(info),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bundled Saudi entries already use our stable form keys; external sources
/// carry English form text that the editor maps to a key itself.
String? _formKeyOf(MedicationInfo info) => info.doseForm;
