// Health metrics screen — weight & blood-pressure tracking with BMI.
//
// Entries live in the `health_metrics` table (DatabaseHelper v3). The weight
// chart uses the last 20 entries so long histories stay readable.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../i18n/strings.dart';
import '../models/health_metric.dart';
import '../models/settings.dart';
import '../providers/providers.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HealthMetricsProvider>();
    final settings = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.healthMetricsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'health_screen_add_metric_fab',
        onPressed: () => _showAddDialog(context, strings),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: strings.addEntry,
        child: const Icon(Icons.add),
      ),
      body: prov.metrics.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.noMetricsYet,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.addFirstMetric,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _summaryRow(prov, settings, strings),
                const SizedBox(height: 16),
                _weightChart(prov, strings),
                const SizedBox(height: 16),
                ...prov.metrics.map(
                  (m) => _MetricRow(
                    metric: m,
                    language: settings.language,
                    onDelete: () =>
                        _confirmDelete(context, prov, m.id, strings),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryRow(
    HealthMetricsProvider prov,
    Settings settings,
    AppStrings strings,
  ) {
    final latest = prov.latest;
    final bmi = BmiCalculator.compute(
      weightKg: latest?.weightKg,
      heightCm: settings.heightCm,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.monitor_weight_outlined,
            label: strings.latestWeight,
            value: latest?.weightKg != null
                ? latest!.weightKg!.toStringAsFixed(1)
                : '—',
            unit: 'kg',
            color: const Color(0xFF0D9488),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.favorite_outline,
            label: strings.bloodPressure,
            value: latest?.systolic != null
                ? '${latest!.systolic}/${latest.diastolic}'
                : '—',
            unit: 'mmHg',
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BmiCard(
            result: bmi,
            label: strings.bmiLabel,
            heightMissing: settings.heightCm == null,
          ),
        ),
      ],
    );
  }

  Widget _weightChart(HealthMetricsProvider prov, AppStrings strings) {
    final weightEntries = prov.metrics
        .where((m) => m.weightKg != null)
        .take(20)
        .toList()
        .reversed
        .toList(); // oldest → newest for the chart
    if (weightEntries.length < 2) return const SizedBox.shrink();

    final gridColor = Colors.grey.shade200;
    final lineColor = Theme.of(context).colorScheme.primary;
    final values = weightEntries.map((m) => m.weightKg!).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 2).clamp(
      0.0,
      double.infinity,
    );
    final maxY = values.reduce((a, b) => a > b ? a : b) + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.weightTrend,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} kg',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightEntries
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.weightKg!),
                          )
                          .toList(),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, _) =>
                            FlDotCirclePainter(radius: 3, color: lineColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HealthMetricsProvider prov,
    String id,
    AppStrings strings,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteMetricConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(strings.ok),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await prov.removeMetric(id);
      messenger.showSnackBar(SnackBar(content: Text(strings.metricDeleted)));
    }
  }

  Future<void> _showAddDialog(BuildContext context, AppStrings strings) async {
    final weightCtrl = TextEditingController();
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();
    var date = DateTime.now();

    // Capture before the async dialog gap (use_build_context_synchronously).
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<HealthMetricsProvider>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.addEntry),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{1,3}[.,]?\d{0,1}'),
                    ),
                  ],
                  decoration: InputDecoration(labelText: strings.weightKg),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.bloodPressure,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sysCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          labelText: strings.systolic,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('/'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: diaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          labelText: strings.diastolic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(
                            () => date = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              date.hour,
                              date.minute,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(strings.today),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
    final systolic = int.tryParse(sysCtrl.text.trim());
    final diastolic = int.tryParse(diaCtrl.text.trim());

    String? validationError;
    if (weight == null && systolic == null && diastolic == null) {
      validationError = strings.errorMetricEmpty;
    } else if (weight != null && (weight < 20 || weight > 400)) {
      validationError = strings.errorWeight;
    } else if (systolic != null && (systolic < 60 || systolic > 260)) {
      validationError = strings.errorBp;
    } else if (diastolic != null && (diastolic < 30 || diastolic > 150)) {
      validationError = strings.errorBp;
    } else if ((systolic == null) != (diastolic == null)) {
      validationError = strings.errorBp;
    } else if (systolic != null && diastolic != null && systolic <= diastolic) {
      validationError = strings.errorBp;
    }

    if (validationError != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    await prov.addMetric(
      HealthMetric(
        id: const Uuid().v4(),
        weightKg: weight,
        systolic: systolic,
        diastolic: diastolic,
        timestamp: date,
      ),
    );
    messenger.showSnackBar(SnackBar(content: Text(strings.metricSaved)));
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final ({double value, BmiCategory category})? result;
  final String label;
  final bool heightMissing;

  const _BmiCard({
    required this.result,
    required this.label,
    required this.heightMissing,
  });

  String _categoryLabel(AppStrings strings, BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return strings.bmiUnderweight;
      case BmiCategory.normal:
        return strings.bmiNormal;
      case BmiCategory.overweight:
        return strings.bmiOverweight;
      case BmiCategory.obese:
        return strings.bmiObese;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = result == null
        ? Colors.grey
        : Color(result!.category.colorHex);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(Icons.straighten, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              result != null ? result!.value.toStringAsFixed(1) : '—',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              result != null
                  ? _categoryLabel(strings, result!.category)
                  : (heightMissing ? strings.heightHint : ''),
            ),
            const SizedBox(height: 2),
            Text(
              'BMI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final HealthMetric metric;
  final Language language;
  final VoidCallback onDelete;

  const _MetricRow({
    required this.metric,
    required this.language,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'd MMM yyyy · HH:mm',
      language.code,
    ).format(metric.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metric.weightKg != null
                      ? Icons.monitor_weight_outlined
                      : Icons.favorite_outline,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (metric.weightKg != null) ...[
                          Text(
                            '${metric.weightKg!.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        if (metric.weightKg != null && metric.systolic != null)
                          const SizedBox(width: 10),
                        if (metric.systolic != null) ...[
                          Text(
                            '${metric.systolic}/${metric.diastolic} mmHg',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _bpColor(
                                metric.systolic!,
                                metric.diastolic!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.grey.shade500,
                tooltip: AppStrings.of(context).delete,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bpColor(int systolic, int diastolic) {
    // Rough AHA-style urgency coloring for display only.
    if (systolic >= 140 || diastolic >= 90) return const Color(0xFFEF4444);
    if (systolic >= 130 || diastolic >= 80) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}
