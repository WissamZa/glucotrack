// Insights screen — HbA1c estimation, glucose trends, and weekly summary
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';
import '../utils/hba1c_calculator.dart';
import '../utils/trend_analysis.dart';
import '../utils/unit_converter.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final rProv = context.watch<ReadingsProvider>();
    final strings = AppStrings.of(context);

    final hba1c = HbA1cCalculator.calculate(rProv.rawReadings);
    final trend = TrendAnalyzer.fromReadings(rProv.rawReadings);
    final weeklyStats = _computeWeeklyStats(rProv.rawReadings, s);

    return Scaffold(
      appBar: AppBar(title: Text(strings.glucoseInsights)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === HbA1c Card ===
          _HbA1cCard(hba1c: hba1c, strings: strings),
          const SizedBox(height: 16),

          // === Trend Card ===
          _TrendCard(trend: trend, strings: strings, isArabic: s.language == Language.ar),
          const SizedBox(height: 16),

          // === Weekly Summary Card ===
          _WeeklySummaryCard(stats: weeklyStats, strings: strings, unit: s.unit),
          const SizedBox(height: 16),

          // === Daily Patterns ===
          if (rProv.rawReadings.isNotEmpty) ...[
            _DailyPatternsCard(readings: rProv.rawReadings, strings: strings, settings: s),
          ],
        ],
      ),
    );
  }

  _WeeklyStats _computeWeeklyStats(List<Reading> readings, Settings s) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final thisWeekReadings = readings
        .where((r) => r.timestamp.isAfter(weekStartDay))
        .toList();

    if (thisWeekReadings.isEmpty) {
      return _WeeklyStats.empty();
    }

    final values = thisWeekReadings.map((r) => r.value).toList();
    final avg = (values.reduce((a, b) => a + b) / values.length).round();
    final inRange = thisWeekReadings
        .where((r) => r.status(s.targetMin, s.targetMax) == ReadingStatus.inRange)
        .length;
    final inRangePct = ((inRange / thisWeekReadings.length) * 100).round();
    final highCount = thisWeekReadings
        .where((r) => {
          ReadingStatus.high,
          ReadingStatus.criticalHigh,
        }.contains(r.status(s.targetMin, s.targetMax)))
        .length;
    final lowCount = thisWeekReadings
        .where((r) => {
          ReadingStatus.low,
          ReadingStatus.criticalLow,
        }.contains(r.status(s.targetMin, s.targetMax)))
        .length;

    return _WeeklyStats(
      readingsCount: thisWeekReadings.length,
      average: avg,
      inRangePct: inRangePct,
      highCount: highCount,
      lowCount: lowCount,
      hasData: true,
    );
  }
}

// ===== HbA1c Card =====
class _HbA1cCard extends StatelessWidget {
  final HbA1cResult? hba1c;
  final AppStrings strings;
  const _HbA1cCard({required this.hba1c, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.hba1cTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (hba1c == null)
              _emptyState(strings.hba1cNoData)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          hba1c!.percentageFormatted,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(hba1c!.category.colorHex),
                          ),
                        ),
                        Text(strings.hba1cEstimate,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          hba1c!.eagFormatted,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(strings.hba1cAverage,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(hba1c!.category.colorHex).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(hba1c!.category.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.isRtl
                          ? hba1c!.category.labelAr
                          : hba1c!.category.label,
                      style: TextStyle(
                        color: Color(hba1c!.category.colorHex),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.science_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
}

// ===== Trend Card =====
class _TrendCard extends StatelessWidget {
  final TrendResult? trend;
  final AppStrings strings;
  final bool isArabic;
  const _TrendCard({required this.trend, required this.strings, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.trendLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (trend == null)
              _emptyState(strings.noTrendData)
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trend!.direction.arrow,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(trend!.direction.colorHex),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TrendAnalyzer.getLocalizedLabel(trend!.direction, isArabic),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(trend!.direction.colorHex),
                        ),
                      ),
                      Text(
                        '${trend!.ratePerHour >= 0 ? "+" : ""}${trend!.ratePerHour.toStringAsFixed(1)} mg/dL/h',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.trending_flat, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
}

// ===== Weekly Summary Card =====
class _WeeklySummaryCard extends StatelessWidget {
  final _WeeklyStats stats;
  final AppStrings strings;
  final GlucoseUnit unit;
  const _WeeklySummaryCard({required this.stats, required this.strings, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_view_week,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.weeklySummary,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (!stats.hasData)
              _emptyState(strings.noReadingsThisWeek)
            else ...[
              Row(
                children: [
                  _miniStat('${stats.readingsCount}', strings.readingsThisWeek,
                      Theme.of(context).colorScheme.primary),
                  _miniStat(
                      UnitConverter.format(stats.average, unit),
                      strings.avgThisWeek,
                      const Color(0xFF0D9488)),
                  _miniStat('${stats.inRangePct}%', strings.timeInRangeWeek,
                      stats.inRangePct >= 70
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _alertChip(
                        '${stats.highCount} ${strings.highReadings}',
                        const Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _alertChip(
                        '${stats.lowCount} ${strings.lowReadings}',
                        const Color(0xFFF59E0B)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _alertChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.calendar_view_week_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
}

// ===== Daily Patterns Card =====
class _DailyPatternsCard extends StatelessWidget {
  final List<Reading> readings;
  final AppStrings strings;
  final Settings settings;
  const _DailyPatternsCard({required this.readings, required this.strings, required this.settings});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Group by reading type
    final typeAvgs = <ReadingType, List<int>>{};
    for (final r in readings.where((r) => r.timestamp.isAfter(todayStart.subtract(const Duration(days: 30))))) {
      typeAvgs.putIfAbsent(r.type, () => []).add(r.value);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  settings.language == Language.ar ? 'أنماط القياس' : 'Measurement Patterns',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...typeAvgs.entries.map((entry) {
              final avg = entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
              final status = Reading(
                id: 'tmp',
                value: avg,
                type: entry.key,
                timestamp: now,
              ).status(settings.targetMin, settings.targetMax);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.readingType(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      UnitConverter.formatWithUnit(avg, settings.unit),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${entry.value.length})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ===== Data classes =====
class _WeeklyStats {
  final int readingsCount;
  final int average;
  final int inRangePct;
  final int highCount;
  final int lowCount;
  final bool hasData;

  _WeeklyStats({
    required this.readingsCount,
    required this.average,
    required this.inRangePct,
    required this.highCount,
    required this.lowCount,
    required this.hasData,
  });

  factory _WeeklyStats.empty() => _WeeklyStats(
        readingsCount: 0,
        average: 0,
        inRangePct: 0,
        highCount: 0,
        lowCount: 0,
        hasData: false,
      );
}
